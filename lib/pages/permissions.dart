import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:location/location.dart';

class Permissions extends StatefulWidget {
  final Widget child;
  const Permissions({super.key, required this.child});

  @override
  State<Permissions> createState() => _PermissionsState();
}

class _PermissionsState extends State<Permissions> {
  final location = Location();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkPermissions(location),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.data["locationPermission"] != true ||
            snapshot.data["backgroundPermission"] != true ||
            snapshot.data["contactPermission"] != true) {
          return GetPermissions(
            backgroundPermission: snapshot.data["backgroundPermission"],
            contactPermission: snapshot.data["contactPermission"],
            locationPermission: snapshot.data["locationPermission"],
            location: location,
          );
        }

        return widget;
      },
    );
  }
}

Future checkPermissions(Location location) async {
  final contactPermission = await FlutterContacts.requestPermission(
    readonly: true,
  );
  final locationPermission = await location.hasPermission();
  final backgroundPermission = await location.enableBackgroundMode();

  return {
    "locationPermission": locationPermission == PermissionStatus.granted,
    "backgroundPermission": backgroundPermission,
    "contactPermission": contactPermission
  };
}

class GetPermissions extends StatelessWidget {
  final bool locationPermission;
  final bool backgroundPermission;
  final bool contactPermission;
  final Location location;
  const GetPermissions({
    super.key,
    required this.backgroundPermission,
    required this.contactPermission,
    required this.locationPermission,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text(
            'חסרות הרשאות',
            textScaleFactor: 3,
          ),
          if (!contactPermission)
            ElevatedButton.icon(
              icon: const Icon(Icons.contact_page_outlined),
              onPressed: () =>
                  FlutterContacts.requestPermission(readonly: true),
              label: const Text('הרשאה לאנשי קשר'),
            ),
          if (!locationPermission)
            ElevatedButton.icon(
              icon: const Icon(Icons.pin_drop_outlined),
              onPressed: () => location.requestPermission(),
              label: Text('הרשאה למיקום'),
            ),
          if (!backgroundPermission)
            ElevatedButton.icon(
              icon: const Icon(Icons.access_time),
              onPressed: () => location.enableBackgroundMode(),
              label: const Text('הרשאה למיקום ברקע'),
            ),
        ],
      ),
    ));
  }
}
