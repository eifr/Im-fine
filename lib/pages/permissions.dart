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
  bool _contactPermission = false;
  bool _backgroundPermission = false;
  bool _locationPermission = false;

  @override
  void initState() {
    _checkPermissions();
    super.initState();
  }

  Future _checkPermissions() async {
    final contactPermission = await FlutterContacts.requestPermission(
      readonly: true,
    );
    final locationPermission = await location.hasPermission();
    bool backgroundPermission;

    if (locationPermission == PermissionStatus.granted) {
      backgroundPermission = await location.enableBackgroundMode();
      if (backgroundPermission) {
        await location.enableBackgroundMode(enable: false);
      }
    } else {
      backgroundPermission = false;
    }
    // final backgroundPermission = await location.isBackgroundModeEnabled();

    setState(() {
      _contactPermission = contactPermission;
      _backgroundPermission = backgroundPermission;
      _locationPermission = locationPermission == PermissionStatus.granted;
    });
  }

  Future<void> _requestContactPermission() async {
    final contactPermissions =
        await FlutterContacts.requestPermission(readonly: true);

    setState(() {
      _contactPermission = contactPermissions;
    });
  }

  Future<void> _requestLocationPermission() async {
    final locationPermissions = await location.requestPermission();

    setState(() {
      _locationPermission = locationPermissions == PermissionStatus.granted;
    });
  }

  Future<void> _requestBackgroundPermission() async {
    final backgroundPermissions = await location.enableBackgroundMode();
    if (backgroundPermissions) {
      await location.enableBackgroundMode(enable: false);
    }
    setState(() {
      _backgroundPermission = backgroundPermissions;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_backgroundPermission || !_contactPermission || !_locationPermission) {
      return GetPermissions(
        backgroundPermission: _backgroundPermission,
        contactPermission: _contactPermission,
        locationPermission: _locationPermission,
        requestBackgroundPermission: _requestBackgroundPermission,
        requestLocationPermission: _requestLocationPermission,
        requestContactPermission: _requestContactPermission,
      );
    }

    return widget.child;
  }
}

class GetPermissions extends StatelessWidget {
  final bool locationPermission;
  final bool backgroundPermission;
  final bool contactPermission;
  final Function requestLocationPermission;
  final Function requestBackgroundPermission;
  final Function requestContactPermission;
  const GetPermissions({
    super.key,
    required this.backgroundPermission,
    required this.contactPermission,
    required this.locationPermission,
    required this.requestLocationPermission,
    required this.requestBackgroundPermission,
    required this.requestContactPermission,
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
              onPressed: () {
                requestContactPermission();
              },
              label: const Text('הרשאה לאנשי קשר'),
            ),
          if (!locationPermission)
            Column(
              children: [
                const Text(
                  'שימוש במיקום נועד למקרים שלא בסדר, נוכל לדווח את המיקום לאנשי קשר שבחרתם',
                  textAlign: TextAlign.center,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pin_drop_outlined),
                  onPressed: () {
                    requestLocationPermission();
                  },
                  label: const Text('הרשאה למיקום'),
                ),
              ],
            ),
          if (!backgroundPermission)
            Column(
              children: [
                const Text(
                  'מיקום בכל זמן נועד שנוכל לשתף את המיקום גם בלי שתצטרכו לפתוח את האפליקציה',
                  textAlign: TextAlign.center,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  onPressed: () {
                    requestBackgroundPermission();
                  },
                  label: const Text('הרשאה למיקום ברקע'),
                ),
              ],
            ),
        ],
      ),
    ));
  }
}
