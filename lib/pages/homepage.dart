import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
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
                    onSelected: (value) => {
                      // createNotification(value!)
                    },
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
                  const FollowersControl(),
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

class FollowersControl extends StatelessWidget {
  const FollowersControl({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      label: const Text(
        'Share my status with:',
      ),
      onSelected: (value) => {
        showModalBottomSheet(
          enableDrag: true,
          showDragHandle: true,
          context: context,
          builder: (context) {
            return const ContactsList();
          },
        )
      },
      enableSearch: false,
      dropdownMenuEntries: const [
        DropdownMenuEntry(
          label: 'List People',
          value: 1,
        ),
        // DropdownMenuEntry(
        //   label: 'Public',
        //   value: 1,
        // ),
        DropdownMenuEntry(
          label: 'All My Contacts',
          value: 1,
        ),
      ],
    );
  }
}

class ContactsList extends StatefulWidget {
  const ContactsList({
    super.key,
  });

  @override
  State<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  List<Contact>? _contacts;
  bool _permissionDenied = false;
  Map _enabledContacts = {};
  Map _disabledContacts = {};

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future _fetchContacts() async {
    Map enabledContacts = {};
    Map disabledContacts = {};

    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() => _permissionDenied = true);
    } else {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() => _contacts = contacts);
    }
    final databaseUsers = (await supabase.from("follows").select().filter(
          'allowed_number',
          'in',
          _contacts?.where((e) => e.phones.isNotEmpty).map(
                (e) => fixPhoneNumber(e.phones.first.number),
              ),
        ) as List);

    Map databaseUsersMap = {
      for (var user in databaseUsers)
        '${user['allowed_number']}': 'valuesOf$user'
    };

    for (final contact in _contacts!) {
      final number = fixPhoneNumber(contact.phones.first.number);
      if (databaseUsersMap.containsKey(number)) {
        enabledContacts[number] = {
          "contact": contact,
          "enabled": databaseUsersMap[number]['is_allowed']
        };
      } else {
        disabledContacts[number] = contact;
      }
    }

    setState(() {
      _enabledContacts = enabledContacts;
      _disabledContacts = disabledContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return const Center(child: Text('Permission denied'));
    }
    // if (_enabledContacts == null) {
    //   return const Center(child: CircularProgressIndicator());
    // }
    var state = false;
    return ListView.builder(
      itemCount: _enabledContacts.length,
      itemBuilder: (context, i) => CheckboxListTile(
        selected: state,
        onChanged: (value) {
          state = true;
          if (_contacts![i].phones.isNotEmpty) {
            print(_contacts?[i].phones.first.number);
            supabase.from('follows').upsert({
              'user_id': supabase.auth.currentUser?.id,
              'allowed_number':
                  (_contacts?[i].phones.first.number)!.startsWith('0')
                      ? '972${_contacts?[i].phones.first.number.substring(1)}'
                      : _contacts?[i].phones.first.number,
              'is_allowed': value
            }).catchError((error) {
              print(error);
            });
          }
        },
        value: false,
        title: Text(_contacts![i].displayName),
        // enabled: ,
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  final Contact contact;
  const ContactPage(this.contact, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(contact.displayName)),
      body: Column(children: [
        Text('First name: ${contact.name.first}'),
        Text('Last name: ${contact.name.last}'),
        Text(
            'Phone number: ${contact.phones.isNotEmpty ? contact.phones.first.number : '(none)'}'),
        Text(
            'Email address: ${contact.emails.isNotEmpty ? contact.emails.first.address : '(none)'}'),
      ]));
}

String fixPhoneNumber(String phoneNumber) {
  return phoneNumber.startsWith('0')
      ? '972${phoneNumber.substring(1)}'
      : phoneNumber;
}
