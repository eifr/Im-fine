import 'dart:async';

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:im_safe/components/im-safe-button.dart';
import 'package:im_safe/location/change_notification.dart';
import 'package:im_safe/location/change_settings.dart';
import 'package:im_safe/location/enable_in_background.dart';
import 'package:im_safe/location/get_location.dart';
import 'package:im_safe/location/listen_location.dart';
import 'package:im_safe/notification-page.dart';
import 'package:im_safe/location/permission_status.dart';
import 'package:im_safe/location/service_enabled.dart';
import 'package:location/location.dart';

Future<void> createNotification(int time) async {
  await AwesomeNotifications().cancelAll();

  String localTimeZone =
      await AwesomeNotifications().getLocalTimeZoneIdentifier();

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      actionType: ActionType.Default,
      title: 'Hello World!',
      body: 'This is my first notification!',
    ),
    // schedule: NotificationInterval(
    //   interval: time,
    //   timeZone: localTimeZone,
    //   repeats: true,
    // ),
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

void main() {
  AwesomeNotifications().initialize(
    // set the icon to null if you want to use the default app icon
    null,
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
      ),
    ],
    // Channel groups are only visual and are not required
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String name = 'Awesome Notifications - Example App';
  static const Color mainColor = Colors.deepPurple;

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
        // This is just a basic example. For real apps, you must show some
        // friendly dialog box before call the request method.
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      } else {
        createNotification(60);
      }
    });

    super.initState();
  }

  Future<void> listenLocation() async {
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
      print(currentLocation);
      setState(() {
        _error = null;

        _location = currentLocation;
      });
    });
    setState(() {});
  }

  Future stopListen() async {
    await _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
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
              final ReceivedAction receivedAction =
                  settings.arguments as ReceivedAction;
              return MyNotificationPage(
                receivedAction: receivedAction,
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: "I'm fine",
        stopListen: stopListen,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final void Function() stopListen;

  const MyHomePage({
    super.key,
    required this.title,
    required this.stopListen,
  });

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final Location location = Location();

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          // mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text(
              'Check with me every:',
            ),
            DropdownMenu(
              onSelected: (value) => createNotification(value!),
              dropdownMenuEntries: const [
                DropdownMenuEntry(
                  label: 'Hour',
                  value: 600,
                ),
                DropdownMenuEntry(
                  label: '6 Hours',
                  value: 600 * 6,
                ),
                DropdownMenuEntry(
                  label: '8 Hours',
                  value: 600 * 8,
                ),
                DropdownMenuEntry(
                  label: '24 Hours',
                  value: 600 * 24,
                ),
              ],
            ),
            const Text(
              'Share my status with:',
            ),
            const DropdownMenu(
              enableSearch: false,
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  label: 'List people',
                  value: 1,
                ),
                DropdownMenuEntry(
                  label: 'Public',
                  value: 1,
                ),
                DropdownMenuEntry(
                  label: 'My contacts',
                  value: 1,
                ),
              ],
            ),
            ImSafeButton(
              stopListen: widget.stopListen,
            ),
            const Divider(height: 32),
            const PermissionStatusWidget(),
            const Divider(height: 32),
            const ServiceEnabledWidget(),
            const Divider(height: 32),
            const GetLocationWidget(),
            const Divider(height: 32),
            const ListenLocationWidget(),
            const Divider(height: 32),
            const ChangeSettings(),
            const Divider(height: 32),
            const EnableInBackgroundWidget(),
            const Divider(height: 32),
            const ChangeNotificationWidget()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
