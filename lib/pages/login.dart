import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_safe/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo:
            kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email for a login link!')),
        );
        _emailController.clear();
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

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (_redirecting) return;
      final session = data.session;
      if (session != null) {
        _redirecting = true;
        Navigator.of(context).pushReplacementNamed('/account');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Sign In'),
      // ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            // padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            children: [
              const Text('Sign in via the Phone Number verification'),
              const SizedBox(height: 18),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.phone,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: Text(_isLoading ? 'Loading' : 'Send Whatsapp Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
