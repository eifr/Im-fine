import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_safe/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _isVerifying = false;
  late final TextEditingController _phoneNumberController =
      TextEditingController();
  late final TextEditingController _otpController = TextEditingController();

  Future<void> _sendOtp() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signInWithOtp(
        phone: '+972${_phoneNumberController.text.trim()}',
        channel: OtpChannel.whatsapp,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('בדקו את הוואטסאפ לקוד אימות!')),
        );
        _isVerifying = true;
        // _phoneNumberController.clear();
      }
    } on AuthException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verify() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.verifyOTP(
        phone: '+972${_phoneNumberController.text.trim()}',
        token: _otpController.text,
        type: OtpType.sms,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('אומת!')),
        );
        _phoneNumberController.clear();
      }
    } on AuthException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // @override
  // void initState() {
  //   _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
  //     // if (_redirecting) return;
  //     // final session = data.session;
  //     // if (session != null) {
  //     //   // _redirecting = true;
  //     //   // Navigator.of(context).pushReplacementNamed('/account');
  //     // }
  //   });
  //   super.initState();
  // }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _otpController.dispose();
    // _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _isVerifying
                ? [
                    const Text('אימות באמצעות וואטסאפ'),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'קוד אימות',
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verify,
                      child: Text(
                        _isLoading ? 'טוען' : 'אימות',
                      ),
                    ),
                  ]
                : [
                    const Text('התחברו באמצעות אימות מספר טלפון'),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9)
                      ],
                      decoration: const InputDecoration(
                        labelText: 'מספר טלפון',
                        suffixText: ' 972+',
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      child: Text(_isLoading ? 'טוען' : 'שלח קוד בוואטסאפ'),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
