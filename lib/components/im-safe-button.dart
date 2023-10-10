import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:location/location.dart';

class ImSafeButton extends StatefulWidget {
  final void Function() stopListen;
  const ImSafeButton({
    super.key,
    required this.stopListen,
  });

  @override
  _ListenLocationState createState() => _ListenLocationState();
}

class _ListenLocationState extends State<ImSafeButton> {
  final Location location = Location();
  final LocalAuthentication auth = LocalAuthentication();

  LocationData? _location;
  StreamSubscription<LocationData>? _locationSubscription;
  String? _error;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Listen location: ${_error ?? '${_location ?? "unknown"}'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            ElevatedButton(
              onPressed: widget.stopListen,
              child: const Text("I'm Safe"),
            )
          ],
        ),
      ],
    );
  }
}
