import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'trackademia_foreground',
      'Trackademia Location Service',
      description: 'This channel is used for location tracking notifications.',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'trackademia_foreground',
        initialNotificationTitle: 'Trackademia Location Service',
        initialNotificationContent: 'Tracking location in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Start periodic location updates
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Trackademia Location Service',
          content: 'Running in background',
        );
      }

      // Get stored user data
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('user_data') ?? '{}');
      final userCode = userData['userCode'];

      if (userCode != null) {
        try {
          // Get current location
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Send location to server
          await http.post(
            Uri.parse('https://stsapi.bccbsis.com/update_location.php'),
            body: {
              'userCode': userCode,
              'lat': position.latitude.toString(),
              'lng': position.longitude.toString(),
            },
          );

          // Store last location locally
          await prefs.setString('last_location', json.encode({
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          }));

          // Update service notification
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Location Updated',
              content: 'Lat: ${position.latitude}, Lng: ${position.longitude}',
            );
          }
        } catch (e) {
          print('Error updating location: $e');
        }
      }
    });
  }
} 