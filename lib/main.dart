import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:im_safe/pages/homepage.dart';
import 'package:im_safe/notification-page.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> createNotification(int time) async {
  // await AwesomeNotifications().cancelAll();

  // await AwesomeNotifications().createNotification(
  //   content: NotificationContent(
  //     id: 10,
  //     channelKey: 'basic_channel',
  //     actionType: ActionType.Default,
  //     title: 'Are you ok?',
  //   ),
  //   // schedule: NotificationInterval(
  //   //   interval: time,
  //   //   timeZone: localTimeZone,
  //   //   repeats: true,
  //   // ),
  // );

  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    channelDescription: 'your channel description',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    // icon: '@mipmap/ic_launcher',
  );
  const darwinNotificationDetails = DarwinNotificationDetails();
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    'הכל בסדר?',
    null,
    notificationDetails,
    payload: 'item x',
  );
}

Future<void> enableInBackground(Location location) async {
  final enabledInBackground = await location.isBackgroundModeEnabled();
  if (!enabledInBackground) {
    await location.enableBackgroundMode();
  }
}

Future<void> getLocationPermissions(Location location) async {
  final permissionGrantedResult = await location.hasPermission();
  if (permissionGrantedResult != PermissionStatus.granted) {
    final permissionRequestedResult = await location.requestPermission();
    if (permissionRequestedResult != PermissionStatus.granted) {
      await getLocationPermissions(location);
    } else {
      await enableInBackground(location);
    }
  } else {
    await enableInBackground(location);
  }
}

// class NotificationController {
//   /// Use this method to detect when a new notification or a schedule is created
//   @pragma("vm:entry-point")
//   static Future<void> onNotificationCreatedMethod(
//       ReceivedNotification receivedNotification) async {
//     // Your code goes here
//   }

//   /// Use this method to detect every time that a new notification is displayed
//   @pragma("vm:entry-point")
//   static Future<void> onNotificationDisplayedMethod(
//       ReceivedNotification receivedNotification) async {
//     // Your code goes here
//   }

//   /// Use this method to detect if the user dismissed a notification
//   @pragma("vm:entry-point")
//   static Future<void> onDismissActionReceivedMethod(
//       ReceivedAction receivedAction) async {
//     // Your code goes here
//   }

//   /// Use this method to detect when the user taps on a notification or action button
//   @pragma("vm:entry-point")
//   static Future<void> onActionReceivedMethod(
//       ReceivedAction receivedAction) async {
//     // Your code goes here

//     // Navigate into pages, avoiding to open the notification details page over another details page already opened
//     MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
//       '/notification-page',
//       (route) => (route.settings.name != '/notification-page') || route.isFirst,
//       arguments: receivedAction,
//     );
//   }
// }

void main() async {
  await Supabase.initialize(
    url: 'https://oknhzacmloylwmrxcsoa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9rbmh6YWNtbG95bHdtcnhjc29hIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTcwMDMxMzYsImV4cCI6MjAxMjU3OTEzNn0.Rko777OCxSIUrhq3rJ0Xsk9Th24jD24XDW7pXZlYuAQ',
  );
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_stat_onesignal_default');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(
    defaultActionName: 'Open notification',
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      if (notificationResponse.payload != null) {
        debugPrint('notification payload: $payload');
      }
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/notification-page',
        (route) =>
            (route.settings.name != '/notification-page') || route.isFirst,
      );
    },
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String name = "אני בסדר";
  // static const Color mainColor = Colors.deepPurple;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<LocationData>? _locationSubscription;
  final Location location = Location();
  LocationData? _location;
  String? _error;

  @override
  void initState() {
    // Only after at least the action method is set, the notification events are delivered
    // AwesomeNotifications().setListeners(
    //     onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    //     onNotificationCreatedMethod:
    //         NotificationController.onNotificationCreatedMethod,
    //     onNotificationDisplayedMethod:
    //         NotificationController.onNotificationDisplayedMethod,
    //     onDismissActionReceivedMethod:
    //         NotificationController.onDismissActionReceivedMethod);
    // AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    //   if (!isAllowed) {
    //     // This is just a basic example. For real apps, you must show some
    //     // friendly dialog box before call the request method.
    //     // This is very important to not harm the user experience
    //     AwesomeNotifications().requestPermissionToSendNotifications();
    //   } else {
    //     createNotification(60);
    //   }
    // });
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    getLocationPermissions(location);
    super.initState();
  }

  Future<void> listenLocation() async {
    try {
      await location.requestService();
      await location.enableBackgroundMode();

      _locationSubscription =
          location.onLocationChanged.handleError((dynamic err) {
        if (err is PlatformException) {
          setState(() {
            _error = err.code;
          });
        }
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
        ]).catchError((e) {
          print(e);
        });

        print(currentLocation);
        setState(() {
          _error = null;

          _location = currentLocation;
        });
      });
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Future stopListen() async {
    // await location.
    await _locationSubscription?.cancel();
    await location.enableBackgroundMode(enable: false);
    setState(() {
      _locationSubscription = null;
    });

    print('Location sub stopped');
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
                stopListen: stopListen,
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        textTheme: GoogleFonts.rubikTextTheme(),
        useMaterial3: true,
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MyHomePage(
          title: "אני בסדר",
          stopListen: stopListen,
        ),
      ),
    );
  }
}
