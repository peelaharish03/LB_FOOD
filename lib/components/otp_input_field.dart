import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

/// Which Android API is used to read the OTP SMS.
enum OtpSmsAutofillMode {
  /// SMS Retriever API: fully automatic, no prompt. The SMS MUST end with the
  /// 11-character app hash (see [OtpInputField.logAppSignature]).
  retriever,

  /// SMS User Consent API: works with any SMS text; the user taps "Allow" once
  /// on a system bottom sheet. No hash required.
  userConsent,

  /// No SMS listening; manual typing / paste / keyboard suggestion only.
  none,
}

/// Reusable OTP input with Android SMS autofill, auto-submit and a resend
/// countdown. Self-contained: depends only on `pinput` and `smart_auth`.
///
/// - Starts listening for the SMS when inserted, stops when disposed.
/// - When all [length] digits are present (typed, pasted or autofilled)
///   [onCompleted] is called.
/// - The resend button is shown when [onResend] is provided; tapping it
///   clears the field, restarts the SMS listener and restarts the countdown.
/// - If the Android listener times out (~5 minutes) it stops silently;
///   manual entry keeps working and resend starts a fresh listener.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    required this.onCompleted,
    this.onChanged,
    this.onResend,
    this.resendCooldown = const Duration(seconds: 30),
    this.androidSmsMode = OtpSmsAutofillMode.userConsent,
    this.senderPhoneNumber,
    this.onAutofillTimeout,
    this.autofocus = true,
    this.enabled = true,
    this.defaultPinTheme,
    this.focusedPinTheme,
    this.submittedPinTheme,
    this.resendTextStyle,
    this.resendActionStyle,
  });

  final int length;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  /// Called when the user taps resend. Hide the resend row by passing null.
  final Future<void> Function()? onResend;
  final Duration resendCooldown;

  final OtpSmsAutofillMode androidSmsMode;

  /// User Consent API only: restrict to SMS from this sender (optional).
  final String? senderPhoneNumber;

  /// Called when the Android SMS listener expires without receiving a code.
  final VoidCallback? onAutofillTimeout;

  final bool autofocus;
  final bool enabled;
  final PinTheme? defaultPinTheme;
  final PinTheme? focusedPinTheme;
  final PinTheme? submittedPinTheme;
  final TextStyle? resendTextStyle;
  final TextStyle? resendActionStyle;

  /// Prints the SMS Retriever app hash for the currently running build to the
  /// debug console. Call once from a debug build; the hash differs per
  /// signing certificate (debug / upload / Play App Signing).
  static Future<String?> logAppSignature() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final res = await SmartAuth.instance.getAppSignature();
    if (res.hasData) {
      debugPrint('OtpInputField: SMS Retriever app hash = ${res.data}');
    } else {
      debugPrint('OtpInputField: could not read app hash: ${res.error}');
    }
    return res.data;
  }

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  final SmartAuth _smartAuth = SmartAuth.instance;

  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  Timer? _resendTimer;
  int _secondsLeft = 0;
  bool _resending = false;

  /// Incremented on every (re)start/stop so results from a stale listener
  /// (e.g. one replaced by a resend) are ignored.
  int _listenSession = 0;

  bool get _smsAutofillSupported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      widget.androidSmsMode != OtpSmsAutofillMode.none;

  // Exactly `length` digits, not part of a longer number.
  String get _codeMatcher => '(?<!\\d)\\d{${widget.length}}(?!\\d)';

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    _startSmsListener();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _stopSmsListener();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _startSmsListener() async {
    if (!_smsAutofillSupported) return;
    await _stopSmsListener();
    final session = _listenSession;

    if (kDebugMode && widget.androidSmsMode == OtpSmsAutofillMode.retriever) {
      OtpInputField.logAppSignature();
    }

    final res =
        widget.androidSmsMode == OtpSmsAutofillMode.retriever
            ? await _smartAuth.getSmsWithRetrieverApi(matcher: _codeMatcher)
            : await _smartAuth.getSmsWithUserConsentApi(
              matcher: _codeMatcher,
              senderPhoneNumber: widget.senderPhoneNumber,
            );

    if (!mounted || session != _listenSession) return;

    final code = res.data?.code;
    if (code != null && code.length == widget.length) {
      // setText moves the cursor to the end and triggers Pinput.onCompleted.
      _controller.setText(code);
      return;
    }

    // Canceled consent sheet or no code in SMS: user can still type manually.
    if (res.isCanceled) return;
    final error = res.error?.toString().toLowerCase() ?? '';
    if (error.contains('timeout') || error.contains('timed out')) {
      widget.onAutofillTimeout?.call();
    } else if (res.hasError) {
      debugPrint('OtpInputField: SMS listener stopped: ${res.error}');
    }
  }

  Future<void> _stopSmsListener() async {
    _listenSession++;
    if (!_smsAutofillSupported) return;
    if (widget.androidSmsMode == OtpSmsAutofillMode.retriever) {
      await _smartAuth.removeSmsRetrieverApiListener();
    } else {
      await _smartAuth.removeUserConsentApiListener();
    }
  }

  void _startResendCountdown() {
    if (widget.onResend == null) return;
    _resendTimer?.cancel();
    setState(() => _secondsLeft = widget.resendCooldown.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _resending || widget.onResend == null) return;
    setState(() => _resending = true);
    _controller.clear();
    // Start listening before the SMS is requested so it can't be missed.
    unawaited(_startSmsListener());
    try {
      await widget.onResend!();
    } finally {
      if (mounted) {
        setState(() => _resending = false);
        _startResendCountdown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTheme =
        widget.defaultPinTheme ??
        PinTheme(
          width: 48,
          height: 48,
          textStyle: theme.textTheme.titleLarge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
        );
    final focusedTheme =
        widget.focusedPinTheme ??
        defaultTheme.copyBorderWith(
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Pinput(
          length: widget.length,
          controller: _controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          // Default hints include AutofillHints.oneTimeCode (iOS / Gboard).
          defaultPinTheme: defaultTheme,
          focusedPinTheme: focusedTheme,
          submittedPinTheme: widget.submittedPinTheme,
          onChanged: widget.onChanged,
          onCompleted: widget.onCompleted,
        ),
        if (widget.onResend != null) ...[
          const SizedBox(height: 16),
          _buildResendRow(theme),
        ],
      ],
    );
  }

  Widget _buildResendRow(ThemeData theme) {
    final textStyle =
        widget.resendTextStyle ??
        theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700);
    final actionStyle =
        widget.resendActionStyle ??
        textStyle?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        );

    if (_resending) {
      return Text('Sending OTP…', style: textStyle);
    }
    if (_secondsLeft > 0) {
      final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
      final s = (_secondsLeft % 60).toString().padLeft(2, '0');
      return Text('Resend OTP in $m:$s', style: textStyle);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Didn’t receive it? ', style: textStyle),
        GestureDetector(
          onTap: _handleResend,
          child: Text('Resend OTP', style: actionStyle),
        ),
      ],
    );
  }
}
