// ignore_for_file: unused_local_variable
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<String?> getDeviceToken() async {
    try {
      print('getDeviceToken() start → platform: ${Platform.operatingSystem}');

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('Notification permission → ${settings.authorizationStatus}');

      if (Platform.isIOS) {
        String? apnsToken;
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        } catch (e) {
          print('getAPNSToken() error → $e');
        }

        print('iOS APNS Token: $apnsToken');
        if (apnsToken == null) {
          print(
              'APNS token is null. On iOS simulator this is expected; test on a real device for APNS/FCM.');
        }
      }

      String? token;
      var retries = 5;
      while (retries > 0) {
        try {
          token = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          print('getToken() error → $e');
        }

        if (token != null && token.isNotEmpty) {
          break;
        }

        print('FCM token is null/empty. Retrying... ($retries)');
        await Future.delayed(const Duration(seconds: 2));
        retries--;
      }

      print('FCM Token: $token');
      if (token == null || token.isEmpty) {
        print(
            'FCM token is still null/empty after retries. This usually means APNs/Push capability is not configured for the iOS app (entitlements / provisioning / APNs key in Firebase).');
      }
      print('getDeviceToken() end');
      return token;
    } catch (e) {
      print('getDeviceToken() error → $e');
      return null;
    }
  }

  void listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      print("Token Refreshed: $token");
    });
  }

  Future<void> requestNotificationPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission for notifications");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("⚠️ User granted provisional permission");
    } else {
      print("User denied notifications");
    }
  }

  Future<void> enableForegroundNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void initializeFirebaseMessaging(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      print(
          "Incoming Notification: ${notification?.title} - ${notification?.body}");
      print("Data: ${message.data}");

      if (Platform.isIOS) {
        enableForegroundNotifications();
      }

      if (Platform.isAndroid) {
        _initializeLocalNotifications(context, message);
        _showNotification(message);
      }
    });
  }

  void _initializeLocalNotifications(
      BuildContext context, RemoteMessage message) async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings();

    var initSettings = const InitializationSettings(
        android: androidInitSettings, iOS: iosInitSettings);

    await _flutterLocalNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      _handleNotificationTap(context, message);
    });
  }

  void _handleNotificationTap(BuildContext context, RemoteMessage message) {
    print("🔔 Notification Clicked");
    if (message.data['type'] == 'text') {}
  }

  Future<void> _showNotification(RemoteMessage message) async {
    AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
      message.notification?.android?.channelId ?? "high_importance_channel",
      "High Importance Notifications",
      description: "This channel is used for important notifications",
      importance: Importance.max,
      playSound: true,
    );

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      androidChannel.id,
      androidChannel.name,
      channelDescription: androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "No Title",
      message.notification?.body ?? "No Body",
      notificationDetails,
    );
  }

  Future forgroundMessage() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
  }

  Future firebaseInit(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        print("Notification title: ${notification.title}");
        print("Notification body: ${notification.body}");
      }

      print("Data: ${message.data.toString()}");

      if (Platform.isIOS) {
        forgroundMessage();
      }

      if (Platform.isAndroid && notification != null) {
        initLocalNotifications(context, message);
        showNotification(message);
      }
    });
  }

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
        print('Notification Clicked: ${response.payload}');
        handleMesssage(context, message);
      }
    });
  }

  void handleMesssage(BuildContext context, RemoteMessage message) {
    print('Handling Message...');
    if (message.data.containsKey('type')) {
      if (message.data['type'] == 'text') {}
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
      message.notification?.android?.channelId ?? 'default_channel',
      message.notification?.android?.channelId ?? 'default_channel',
      importance: Importance.max,
      showBadge: true,
      playSound: true,
    );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      androidNotificationChannel.id.toString(),
      androidNotificationChannel.name.toString(),
      channelDescription: 'Flutter Notifications',
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

    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
          0,
          message.notification?.title ?? 'No Title',
          message.notification?.body ?? 'No Body',
          notificationDetails);
    });
  }

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

  Future isRefreshToken() async {
    _messaging.onTokenRefresh.listen((newToken) {
      print('Token Refreshed: $newToken');
    });
  }

  Future<void> setupNotificationInteraction(BuildContext context) async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(context, initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(context, message);
    });
  }
}
