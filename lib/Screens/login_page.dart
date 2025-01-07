import 'package:flutter/material.dart';
import 'package:todo_flutter/Screens/todo_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_page.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final Logger logger = Logger();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPhoneNumberField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 20),
              _buildLoginButtonField(),
              const SizedBox(height: 20),
              _buildNavigateToRegistration(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      controller: _phoneNumberController,
      decoration: const InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButtonField() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitLoginForm,
      child: const Text('Login'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9395D2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }

  Widget _buildNavigateToRegistration() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegistrationPage()),
        );
      },
      child: const Text('Don\'t have an account? Register here'),
    );
  }

  void _submitLoginForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _submitLogin();
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginToken', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginToken');
  }

  Future<void> _submitLogin() async {
    final String phoneNumber = _phoneNumberController.text;
    final String password = _passwordController.text;
    const String url = 'https://todo-mww8.onrender.com/api/auth/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSnackBar('Login Successfull');
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final String token = responseBody['token'];
        await _saveToken(token);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else {
        if (!mounted) return;
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final String errorMessage =
            responseBody['message'] ?? 'Registration failed.';
        _showSnackBar(errorMessage);
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('An error occurred: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
