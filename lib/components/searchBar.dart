import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_basket/core/constants/colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CategorySearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode; 

  const CategorySearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.focusNode,
  });

  @override
  _CategorySearchBarState createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar> {
  final bool _isListening = false;
  late stt.SpeechToText _speech;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller = TextEditingController();
  }


  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          decoration: BoxDecoration(
            color: AppColor.White,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _controller,
            focusNode: widget.focusNode, // <-- Use provided focus node
            onChanged: widget.onChanged,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: InputBorder.none,
              hintText: "${widget.hintText}...",
              hintStyle: GoogleFonts.poppins(
                color: Colors.black.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.black),
              // suffixIcon: IconButton(
              //   icon: _isListening
              //       ? const Icon(Icons.mic_none, color: Colors.green)
              //       : const Icon(Icons.mic, color: Colors.black),
              //   onPressed: _toggleMic,
              // ),
            ),
          ),
        ),
        if (_isListening)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Listening...",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.greenAccent,
              ),
            ),
          ),
      ],
    );
  }
}
