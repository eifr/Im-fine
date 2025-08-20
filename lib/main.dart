import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:im_safe/pages/homepage.dart';
import 'package:im_safe/notification-page.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> createNotification(
    {Duration time = const Duration(seconds: 60)}) async {
  await AwesomeNotifications().cancelAll();
  String localTimeZone =
      await AwesomeNotifications().getLocalTimeZoneIdentifier();

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      actionType: ActionType.Default,
      title: 'הכל בסדר?',
    ),
    schedule: NotificationInterval(
      interval: time,
      timeZone: localTimeZone,
      repeats: true,
    ),
  );
}

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here

    // Navigate into pages, avoiding to open the notification details page over another details page already opened
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/notification-page',
      (route) => (route.settings.name != '/notification-page') || route.isFirst,
      arguments: receivedAction,
    );
  }
}

void main() async {
  await Supabase.initialize(url: '', anonKey: '');

  AwesomeNotifications().initialize(
    'resource://drawable/ic_stat_onesignal_default',
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
      )
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'basic_channel_group',
        channelGroupName: 'Basic group',
      )
    ],
    debug: true,
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String name = "אני בסדר";

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<LocationData>? _locationSubscription;
  final Location location = Location();

  @override
  void initState() {
    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    super.initState();
  }

  Future<void> listenLocation() async {
    try {
      await location.requestService();
      await location.enableBackgroundMode();

      _locationSubscription =
          location.onLocationChanged.handleError((dynamic err) {
        _locationSubscription?.cancel();
        setState(() {
          _locationSubscription = null;
        });
      }).listen((currentLocation) {
        supabase.from('user_status').insert([
          {
            'is_fine': false,
            'user_id': supabase.auth.currentUser?.id,
            'point':
                'POINT(${currentLocation.longitude} ${currentLocation.latitude})',
          },
        ]);
      });
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Future stopListen() async {
    await _locationSubscription?.cancel();
    await location.enableBackgroundMode(enable: false);
    setState(() {
      _locationSubscription = null;
    });
  }

  Future imSafe() async {
    await stopListen();
    await supabase.from('user_status').insert([
      {
        'is_fine': true,
        'user_id': supabase.auth.currentUser?.id,
      },
    ]);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      title: 'Flutter Demo',
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => MyHomePage(
                title: MyApp.name,
                stopListen: () => imSafe(),
              ),
            );

          case '/notification-page':
            return MaterialPageRoute(builder: (context) {
              // final ReceivedAction receivedAction =
              //     settings.arguments as ReceivedAction;
              return MyNotificationPage(
                // receivedAction: receivedAction,
                subscribeToLocation: listenLocation,
              );
            });

          default:
            assert(false, 'Page ${settings.name} not found');
            return null;
        }
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MyHomePage(
          title: "אני בסדר",
          stopListen: () => imSafe(),
        ),
      ),
    );
  }
}
