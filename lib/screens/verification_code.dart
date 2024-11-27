import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart'; 
import 'update_password.dart'; 
import 'package:flutter_application_3/widgets/custom_scaffold.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';
import 'package:flutter_application_3/screens/login_screen.dart';
import 'package:flutter_application_3/screens/public_info.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
class VerificationCodeScreen extends StatefulWidget {
  final String email; // To send verification code to email
  final String flag;
  const VerificationCodeScreen({super.key, required this.email, required this.flag});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  String _currentText = "";

  Future<void> _verifyCode() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/verifyCode'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'verificationCode': _currentText,
        }),
      );

     if (response.statusCode == 200) {
  final token = jsonDecode(response.body)['token']; // Extract token

  // Make sure you await the result from storage.read
final userid = await storage.read(key: 'userid') ?? 'default_user_id';

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        // Access flag from the current widget's state
        if (widget.flag == '1') {
          return UpdatePasswordScreen(token: token);
        } else if (widget.flag == '2') {
          return SignInScreen();
        } else if (widget.flag == '3') {
          return PublicInfo(userId: userid);
        } else {
          // Default return if no condition matches
          return SignInScreen(); // You can replace this with any default screen widget
        }
      },
    ),
  );
}
 else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid verification code')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(height: 10),
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
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Enter Verification Code',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff613089),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      const Text(
                        'We have sent a verification code to your email.',
                        style: TextStyle(fontSize: 16.0, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40.0),
                      
                      // Verification Code Input Field
                      PinCodeTextField(
                        appContext: context,
                        length: 4,
                        keyboardType: TextInputType.number,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(10),
                          fieldHeight: 60,
                          fieldWidth: 50,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          activeColor: const Color(0xff613089),
                          selectedColor: const Color(0xffb41391),
                          inactiveColor: Colors.grey,
                        ),
                        animationDuration: const Duration(milliseconds: 300),
                        backgroundColor: Colors.transparent,
                        enableActiveFill: true,
                        onCompleted: (v) {
                          setState(() {
                            _currentText = v;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _currentText = value;
                          });
                        },
                        beforeTextPaste: (text) {
                          return true;
                        },
                      ),
                      const SizedBox(height: 40.0),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff613089),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(fontSize: 16.0),
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
