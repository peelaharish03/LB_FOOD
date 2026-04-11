import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// FIX: Removed all duplicate methods that were causing double notifications on Android.
//
// WHAT WAS REMOVED and WHY:
//   - initializeFirebaseMessaging()     → duplicate of firebaseInit()
//   - _initializeLocalNotifications()   → duplicate of initLocalNotifications()
//   - _showNotification()               → duplicate of showNotification()
//   - _handleNotificationTap()          → duplicate of handleMesssage()
//   - setupNotificationInteraction()    → duplicate of setupInteractMessage()
//   - enableForegroundNotifications()   → duplicate of forgroundMessage()
//
// Both MyApp.initState() and SplashScreen.initNotifications() were calling
// FirebaseMessaging.onMessage.listen() — adding two listeners — which caused
// Android to show every foreground notification TWICE.
//
// NOW: Only the methods called from SplashScreen.initNotifications() remain.
// MyApp.initState() no longer sets up notifications (see main.dart).

class NotificationServices {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Called from SplashScreen to get and return the FCM device token.
  // Also requests notification permissions internally.
  Future<String?> getDeviceToken() async {
    try {
      debugPrint(
          'getDeviceToken() start → platform: ${Platform.operatingSystem}');

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint(
          'Notification permission → ${settings.authorizationStatus}');

      if (Platform.isIOS) {
        String? apnsToken;
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        } catch (e) {
          debugPrint('getAPNSToken() error → $e');
        }

        debugPrint('iOS APNS Token: $apnsToken');
        if (apnsToken == null) {
          debugPrint(
              'APNS token is null. On iOS simulator this is expected; test on a real device for APNS/FCM.');
        }
      }

      String? token;
      var retries = 5;
      while (retries > 0) {
        try {
          token = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          debugPrint('getToken() error → $e');
        }

        if (token != null && token.isNotEmpty) {
          break;
        }

        debugPrint('FCM token is null/empty. Retrying... ($retries)');
        await Future.delayed(const Duration(seconds: 2));
        retries--;
      }

      if (token == null || token.isEmpty) {
        debugPrint(
            'FCM token still null/empty after retries. Check APNs/Push capability for iOS.');
      }
      debugPrint('getDeviceToken() end');
      return token;
    } catch (e) {
      debugPrint('getDeviceToken() error → $e');
      return null;
    }
  }

  // Sets foreground notification presentation options.
  // Called from SplashScreen.initNotifications() as forgroundMessage().
  Future<void> forgroundMessage() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
  }

  // Sets up the foreground message listener (onMessage).
  // Called ONCE from SplashScreen.initNotifications().
  // Do NOT call this from MyApp — it would create a second listener.
  Future<void> firebaseInit(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;

      if (notification != null) {
        debugPrint('Notification title: ${notification.title}');
        debugPrint('Notification body: ${notification.body}');
      }

      debugPrint('Data: ${message.data.toString()}');

      if (Platform.isAndroid && notification != null) {
        initLocalNotifications(context, message);
        showNotification(message);
      }
      // iOS handles foreground display via setForegroundNotificationPresentationOptions
    });
  }

  // Initialises flutter_local_notifications for Android.
  void initLocalNotifications(
      BuildContext context, RemoteMessage message) async {
    var androidInitSettings =
        const AndroidInitializationSettings('ic_notification');
    var iosInitSettings = const DarwinInitializationSettings();

    var initSettings = InitializationSettings(
        android: androidInitSettings, iOS: iosInitSettings);

    await _flutterLocalNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        debugPrint('Notification Clicked: ${response.payload}');
        handleMesssage(context, message);
      }
    });
  }

  // Handles navigation/logic when a notification is tapped.
  void handleMesssage(BuildContext context, RemoteMessage message) {
    debugPrint('Handling Message...');
    if (message.data.containsKey('type')) {
      // TODO: Add navigation logic per notification type here
      if (message.data['type'] == 'text') {}
    }
  }

  // Displays the notification banner using flutter_local_notifications.
  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
      message.notification?.android?.channelId ?? 'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.max,
      showBadge: true,
      playSound: true,
    );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      androidNotificationChannel.id,
      androidNotificationChannel.name,
      channelDescription: androidNotificationChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true);

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
      notificationDetails,
    );
  }

  // Handles the app-open-from-notification case (terminated + background taps).
  // Called from SplashScreen.initNotifications().
  Future<void> setupInteractMessage(BuildContext context) async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      handleMesssage(context, initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleMesssage(context, event);
    });
  }

  // Listens for FCM token refreshes.
  // Called from SplashScreen.initNotifications().
  Future<void> isRefreshToken() async {
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('Token Refreshed: $newToken');
    });
  }

  // Wrapper method for backward compatibility
  // Calls getDeviceToken() which handles permission requests internally
  Future<void> requestNotificationPermissions() async {
    await getDeviceToken();
  }

  // Wrapper method for backward compatibility  
  // Calls the existing forgroundMessage() method
  Future<void> enableForegroundNotifications() async {
    await forgroundMessage();
  }

  // Wrapper method for backward compatibility
  // Calls the existing firebaseInit() method
  Future<void> initializeFirebaseMessaging(BuildContext context) async {
    await firebaseInit(context);
  }

  // Wrapper method for backward compatibility
  // Calls the existing setupInteractMessage() method
  Future<void> setupNotificationInteraction(BuildContext context) async {
    await setupInteractMessage(context);
  }
}
