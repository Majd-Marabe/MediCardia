import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:flutter_application_3/widgets/custom_scaffold.dart';
import 'package:http/http.dart' as http; 
import 'constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_application_3/screens/verification_code.dart';

final storage = FlutterSecureStorage();

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignupKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController(); // Location Controller
  bool agreePersonalData = true;
  bool _obscureText = true; // New variable to control password visibility

  // Regular expression for email validation
  final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Function to toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText; // Toggle the obscureText state
    });
  }

  Future<void> _submitSignUp() async {
    if (!_formSignupKey.currentState!.validate() || !agreePersonalData) {
      if (!agreePersonalData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the processing of personal data')),
        );
      }
      return;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/users/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _fullNameController.text,
          'email': _emailController.text,
          'password_hash': _passwordController.text,
          'location': _locationController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the response body to get the user ID
        final responseData = jsonDecode(response.body);
        
        final userId = responseData['_id']; // Extract user ID from the response
        await storage.write(key: 'userid', value: userId);

        // Success
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Sign up successful: $responseData')),
        );

        // Navigate to PublicInfo screen and pass userId
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  VerificationCodeScreen(email: _emailController.text,flag: '3')), // PublicInfo(userId: userId) Pass userId to the PublicInfo screen
        );
      } else {
        // Server error or validation issue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign up: ${response.body}')),
        );
      }
    } catch (e) {
      // Network or server error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(
              height: 10,
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignupKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        // App Logo and Name
                      Column(
                        children: [
                          Image.asset(
                            'assets/images/appLogo.png', // Path to the logo
                            height: 100,
                            color: Color(0xff613089),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'MediCardia', // App name
                            style: TextStyle(
                              fontSize: 40.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'BAUHS93', // Set font family
                              color: Color(0xff613089),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40.0),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Full name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: const TextStyle(color: Color(0xff613089)),
                          hintText: 'Enter Full Name',
                          hintStyle: const TextStyle(color: Color(0xff613089)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.person, color: Color(0xff613089)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xffb41391),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Email';
                          } else if (!_emailRegExp.hasMatch(value)) {
                            return 'Please enter a valid Email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Color(0xff613089)),
                          hintText: 'Enter Email',
                          hintStyle: const TextStyle(color: Color(0xff613089)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.email, color: Color(0xff613089)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xffb41391),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a location';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Location',
                          labelStyle: const TextStyle(color: Color(0xff613089)),
                          hintText: 'Enter Location',
                          hintStyle: const TextStyle(color: Color(0xff613089)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xff613089)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xffb41391),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText, // Use the state variable
                        obscuringCharacter: '•',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Color(0xff613089)),
                          hintText: 'Enter Password',
                          hintStyle: const TextStyle(color: Color(0xff613089)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xff613089)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xff613089),
                            ),
                            onPressed: _togglePasswordVisibility, // Toggle password visibility
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xffb41391),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),

                    // Agreement Checkbox
Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    Checkbox(
      value: agreePersonalData,
      onChanged: (value) {
        setState(() {
          agreePersonalData = value ?? false;
        });
      },
      activeColor: const Color(0xff613089), // This changes the tick color
    ),
    const Text('I agree to the processing of personal data'),
  ],
),

                      const SizedBox(height: 25.0),

                      // Signup Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff613089),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _submitSignUp, // Trigger the signup function
                        child: const Text(
      'Create Account',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    
    ),

                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}