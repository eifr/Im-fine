import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:im_safe/main.dart';
import 'package:im_safe/pages/follow-status.dart';
import 'package:im_safe/pages/login.dart';
import 'package:im_safe/pages/permissions.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const hourInSeconds = 3600;

class MyHomePage extends StatefulWidget {
  final VoidCallback stopListen;

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
  Session? _session;
  int currentPageIndex = 0;

  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        if (data.session != null) {
          OneSignal.initialize("341c3a51-a9c3-49e2-b467-41d319bfc720");
          OneSignal.login(supabase.auth.currentUser!.id);
          OneSignal.Notifications.requestPermission(true);
        }
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
    if (_session == null) {
      return SafeArea(
        child: Permissions(
          child: Scaffold(
            bottomNavigationBar: NavigationBar(
              onDestinationSelected: (int index) {
                setState(() {
                  currentPageIndex = index;
                });
              },
              selectedIndex: currentPageIndex,
              destinations: const [
                NavigationDestination(
                  selectedIcon: Icon(
                    Icons.people_alt,
                  ),
                  icon: Icon(
                    Icons.people_alt_outlined,
                  ),
                  label: 'כולם',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.self_improvement,
                  ),
                  label: 'אני',
                )
              ],
            ),
            body: [
              const FollowStatus(),
              SelfPage(widget: widget)
            ][currentPageIndex],
          ),
        ),
      );
    } else {
      return const LoginPage();
    }
  }
}

class SelfPage extends StatelessWidget {
  const SelfPage({
    super.key,
    required this.widget,
  });

  final MyHomePage widget;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Column(
            children: [
              Text('הכל בסדר?', textScaler: TextScaler.linear(3)),
              Text('האפליקציה עוקבת אחרי המיקום'),
              Text('לחצו על המגן בכדי לאמת שאתם בסדר'),
            ],
          ),
          IconButton.filled(
            iconSize: 150,
            onPressed: () => {
              widget.stopListen(),
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'הודענו שהכל בסדר 🫶',
                  ),
                ),
              )
            },
            icon: const Icon(Icons.shield_outlined),
          ),
          Column(
            children: [
              DropdownMenu(
                label: const Text(
                  'תבדוק איתי כל:',
                ),
                onSelected: (value) => {
                  createNotification(time: Duration(seconds: value ?? 60)),
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    label: 'שעה',
                    value: hourInSeconds,
                  ),
                  DropdownMenuEntry(
                    label: '6 שעות',
                    value: hourInSeconds * 6,
                  ),
                  DropdownMenuEntry(
                    label: '8 שעות',
                    value: hourInSeconds * 8,
                  ),
                  DropdownMenuEntry(
                    label: '24 שעות',
                    value: hourInSeconds * 24,
                  ),
                  DropdownMenuEntry(
                    label: 'שבוע',
                    value: hourInSeconds * 24 * 7,
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => showModalBottomSheet(
                  isScrollControlled: true,
                  enableDrag: true,
                  showDragHandle: true,
                  context: context,
                  useSafeArea: true,
                  builder: (context) {
                    return const ContactsList();
                  },
                ),
                label: const Text('אנשי קשר'),
                icon: const Icon(Icons.check_box_outlined),
              ),
              TextButton.icon(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () {
                  OneSignal.logout();
                  supabase.auth.signOut();
                },
                label: const Text('התנתקות'),
              ),
            ],
          ),
        ],
      ),
    );
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
        'שתף את הסטטוס שלי עם:',
      ),
      onSelected: (value) => {
        showModalBottomSheet(
          isScrollControlled: true,
          enableDrag: true,
          showDragHandle: true,
          context: context,
          useSafeArea: true,
          builder: (context) {
            return const ContactsList();
          },
        )
      },
      dropdownMenuEntries: const [
        DropdownMenuEntry(
          label: 'בחירה מרשימה',
          value: 1,
        ),
        DropdownMenuEntry(
          label: 'כל אנשי הקשר שלי',
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
  List _enabledContacts = [];
  List _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future _fetchContacts() async {
    List enabledContacts = [];

    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() => _permissionDenied = true);
    } else {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() => _contacts = contacts);
    }
    final databaseUsers = (await supabase.from("follows").select() as List);

    Map databaseUsersMap = {
      for (var user in databaseUsers) '${user['allowed_number']}': user
    };

    for (final contact in _contacts!) {
      if (contact.phones.isEmpty) {
        continue;
      }
      final number = fixPhoneNumber(contact.phones.first.number);
      if (databaseUsersMap[number]?['is_allowed'] == true) {
        enabledContacts.insert(
          0,
          {
            "contact": contact,
            "enabled": true,
            "id": databaseUsersMap[number]?['id'],
          },
        );
      } else {
        enabledContacts.add(
          {
            "contact": contact,
            "enabled": false,
            "id": databaseUsersMap[number]?['id']
          },
        );
      }
    }

    setState(() {
      _enabledContacts = enabledContacts;
      _filteredContacts = enabledContacts;
    });
  }

  void filterSearchResults(String query) {
    setState(() {
      _filteredContacts = query.isNotEmpty
          ? _enabledContacts
              .where((item) => item['contact']
                  .displayName
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList()
          : _enabledContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return const Center(child: Text('Permission denied'));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                filterSearchResults(value);
              },
              decoration: const InputDecoration(
                labelText: "חיפוש",
                hintText: "חיפוש",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, i) {
                  return CheckboxListTile(
                    onChanged: (value) {
                      var args = {
                        'user_id': supabase.auth.currentUser?.id,
                        'allowed_number': fixPhoneNumber(
                          _filteredContacts[i]['contact'].phones.first.number,
                        ),
                        'is_allowed': value
                      };
                      if (_filteredContacts[i]['id'] != null) {
                        args['id'] = _filteredContacts[i]['id'];
                      }
                      if (_filteredContacts[i]['contact'].phones.isNotEmpty) {
                        setState(() {
                          _filteredContacts[i]['enabled'] = value;
                        });
                        supabase
                            .from('follows')
                            .upsert(args)
                            .then((_) => _fetchContacts())
                            .catchError(print);
                      }
                    },
                    value: _filteredContacts[i]['enabled'] ?? false,
                    title: Text(_filteredContacts[i]['contact'].displayName),
                  );
                }),
          ),
        ],
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  final Contact contact;
  const ContactPage(this.contact, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Text('First name: ${contact.name.first}'),
          Text('Last name: ${contact.name.last}'),
          Text(
              'Phone number: ${contact.phones.isNotEmpty ? contact.phones.first.number : '(none)'}'),
          Text(
              'Email address: ${contact.emails.isNotEmpty ? contact.emails.first.address : '(none)'}'),
        ]),
      );
}

String fixPhoneNumber(String phoneNumber) {
  final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[ \-()]'), '');

  switch (cleanPhoneNumber[0]) {
    case '0':
      return '972${cleanPhoneNumber.substring(1)}';
    case '+':
      return cleanPhoneNumber.substring(1);
  }

  return cleanPhoneNumber;
}
