import 'dart:async';

import 'package:flutter/material.dart';
import 'package:im_safe/components/im-safe-button.dart';
import 'package:im_safe/main.dart';
import 'package:im_safe/pages/login.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyHomePage extends StatefulWidget {
  final void Function() stopListen;

  const MyHomePage({
    super.key,
    required this.title,
    required this.stopListen,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Location location = Location();
  Session? _session;

  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _session = data.session;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    if (_session != null) {
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
          child: Column(
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
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownMenu(
                    label: const Text(
                      'Check with me every:',
                    ),
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
                  const SizedBox(height: 30),
                  const DropdownMenu(
                    label: Text(
                      'Share my status with:',
                    ),
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
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ImSafeButton(
                    stopListen: widget.stopListen,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: supabase.auth.signOut,
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return const LoginPage();
    }
  }
}
