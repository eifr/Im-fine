import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:location/location.dart';

class MyNotificationPage extends StatefulWidget {
  final Future<void> Function() subscribeToLocation;
  const MyNotificationPage({
    super.key,
    receivedAction,
    required this.subscribeToLocation,
  });

  @override
  State<MyNotificationPage> createState() => _MyNotificationPageState();
}

class _MyNotificationPageState extends State<MyNotificationPage> {
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;
  final Location location = Location();

  String? _error;

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (isSupported) => setState(() => _supportState = isSupported
              ? _SupportState.supported
              : _SupportState.unsupported),
        );
    _initAuth();
  }

  Future<void> _checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      print(e);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> _getAvailableBiometrics() async {
    late List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      availableBiometrics = <BiometricType>[];
      print(e);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      // bool serviceEnabled = await location.serviceEnabled();
      // if (!serviceEnabled) {
      //   serviceEnabled = await location.requestService();
      //   if (!serviceEnabled) {
      //     return;
      //   }
      // }

      // PermissionStatus permissionGranted = await location.hasPermission();
      // if (permissionGranted == PermissionStatus.denied) {
      //   permissionGranted = await location.requestPermission();
      //   if (permissionGranted != PermissionStatus.granted) {
      //     return;
      //   }
      // }

      authenticated = await auth.authenticate(
        localizedReason: 'Let OS determine authentication method',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on Error catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - $e';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    setState(
        () => _authorized = authenticated ? 'Authorized' : 'Not Authorized');
  }

  Future<void> _initAuth() async {
    await _authenticate();
    if (_authorized != "Authorized") {
      await widget.subscribeToLocation();
    }
    SystemNavigator.pop();
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason:
            'Scan your fingerprint (or face or whatever) to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticating';
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    final String message = authenticated ? 'Authorized' : 'Not Authorized';
    setState(() {
      _authorized = message;
    });
  }

  Future<void> _cancelAuthentication() async {
    await auth.stopAuthentication();
    setState(() => _isAuthenticating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('הכל בסדר?'),
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: 30),
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('אימות קצר שנדע שהכל בסדר'),
                Icon(
                  Icons.shield_outlined,
                  size: 200,
                  color: Theme.of(context).primaryColor,
                )
                //   if (_supportState == _SupportState.unknown)
                //     const CircularProgressIndicator()
                //   else if (_supportState == _SupportState.supported)
                //     const Text('This device is supported')
                //   else
                //     const Text('This device is not supported'),
                //   const Divider(height: 100),
                //   Text('Can check biometrics: $_canCheckBiometrics\n'),
                //   ElevatedButton(
                //     onPressed: _checkBiometrics,
                //     child: const Text('Check biometrics'),
                //   ),
                //   const Divider(height: 100),
                //   Text('Available biometrics: $_availableBiometrics\n'),
                //   ElevatedButton(
                //     onPressed: _getAvailableBiometrics,
                //     child: const Text('Get available biometrics'),
                //   ),
                //   const Divider(height: 100),
                //   Text('Current State: $_authorized\n'),
                //   if (_isAuthenticating)
                //     ElevatedButton(
                //       onPressed: _cancelAuthentication,
                //       child: const Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: <Widget>[
                //           Text('Cancel Authentication'),
                //           Icon(Icons.cancel),
                //         ],
                //       ),
                //     )
                //   else
                //     Column(
                //       children: <Widget>[
                //         ElevatedButton(
                //           onPressed: _authenticate,
                //           child: const Row(
                //             mainAxisSize: MainAxisSize.min,
                //             children: <Widget>[
                //               Text('Authenticate'),
                //               Icon(Icons.perm_device_information),
                //             ],
                //           ),
                //         ),
                //         ElevatedButton(
                //           onPressed: _authenticateWithBiometrics,
                //           child: Row(
                //             mainAxisSize: MainAxisSize.min,
                //             children: <Widget>[
                //               Text(_isAuthenticating
                //                   ? 'Cancel'
                //                   : 'Authenticate: biometrics only'),
                //               const Icon(Icons.fingerprint),
                //             ],
                //           ),
                //         ),
                //       ],
                //     ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}
