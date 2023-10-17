import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:im_safe/main.dart';
import 'package:im_safe/pages/homepage.dart';
import 'package:intl/intl.dart';

class FollowStatus extends StatefulWidget {
  const FollowStatus({super.key});

  @override
  State<FollowStatus> createState() => _FollowStatusState();
}

class _FollowStatusState extends State<FollowStatus> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: mapContacts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          print(snapshot.data);
          return Padding(
            padding: const EdgeInsets.fromLTRB(0.8, 40, 0.8, 0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'מי בסדר',
                    textScaleFactor: 3,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data["contacts"].length,
                      itemBuilder: (context, index) => ListTile(
                        leading: CircleAvatar(
                          child: Text(snapshot
                              .data["contacts"][index]["contact"]
                              .displayName[0]),
                        ),
                        title: Text(
                          snapshot
                              .data["contacts"][index]["contact"].displayName,
                        ),
                        subtitle: Text(
                          'הכל בסדר! עודכן ב-${DateFormat('H:m (dd/MM/yy)').format(
                            DateTime.parse(
                              snapshot.data["contacts"][index]["status"]
                                  ["created_at"],
                            ),
                          )}',
                        ),
                        trailing: Icon(
                          Icons.shield_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  if (snapshot.data["nonContacts"].length > 0)
                    Expanded(
                      child: Column(
                        children: [
                          const Text('לא באנשי הקשר שלי'),
                          ListView.builder(
                            itemCount: snapshot.data["nonContacts"].length,
                            itemBuilder: (context, index) => ListTile(
                              leading:
                                  const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(
                                '${snapshot.data["nonContacts"][index]["status"]["phone"]}+',
                              ),
                              subtitle: Text(
                                'הכל בסדר! עודכן ב-${DateFormat('H:m (dd/MM/yy)').format(
                                  DateTime.parse(
                                    snapshot.data["nonContacts"][index]
                                        ["status"]["created_at"],
                                  ),
                                )}',
                              ),
                              trailing: Icon(
                                Icons.shield_outlined,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        });
  }
}

Future mapContacts() async {
  List databaseUsers = await supabase.from('last_status').select();
  await FlutterContacts.requestPermission(readonly: true);
  List<Contact>? localContacts =
      await FlutterContacts.getContacts(withProperties: true, withPhoto: true);
  final localContactsUsersMap = {
    for (var user
        in localContacts.where((element) => element.phones.isNotEmpty))
      fixPhoneNumber(user.phones.first.number): user
  };

  final contacts = [];
  final nonContacts = [];

  for (final user in databaseUsers) {
    if (localContactsUsersMap[user["phone"]] != null) {
      contacts.add(
        {
          "status": user,
          "contact": localContactsUsersMap[user["phone"]],
        },
      );
    } else {
      nonContacts.add({
        "status": user,
      });
    }
  }

  return {
    "contacts": contacts,
    "nonContacts": nonContacts,
  };
}
