import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'signup.dart';
import 'package:http/http.dart' as http; // Import HTTP package
import 'dart:convert'; // To handle JSON

class LoginWidget extends StatefulWidget {
  @override
  _LoginWidgetState createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _pinController = TextEditingController(); // For PIN login
  String pin = ''; // Track the entered PIN
  bool _isPinCorrect = true; // Flag to track if the PIN is correct

  // Cognito User Pool configuration
  final _userPool = CognitoUserPool(
    'ap-south-1_gScvuXkq9', // Your user pool ID
    '5iehem84fdr043cas2l3vh4hhf', // Your client ID
  );

  // Secure storage instance
  final _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity, // Ensure it stretches vertically
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Enter your PIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // PIN input section with interactive circular inputs
                _buildPinInputFields(),
                const SizedBox(height: 30),
                // Custom numeric keypad
                _buildPinKeyPad(),
                const SizedBox(height: 30),
                // Sign up redirect button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpWidget()),
                    );
                  },
                  child: const Text(
                    'New User? Sign up',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildPinInput(index),
        );
      }),
    );
  }

  Widget _buildPinInput(int index) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pin.length > index
            ? (_isPinCorrect ? Colors.green : Colors.red)
            : Colors.blue.shade100,
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Center(
        child: Text(
          pin.length > index ? pin[index] : '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Custom function to update the PIN input on tap
  void _onPinDigitPressed(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
      });

      // If the 4th digit is entered, attempt to log in
      if (pin.length == 4) {
        _onLoginPressed();
      }
    }
  }

  void _onLoginPressed() async {
    if (pin.length < 4) {
      return; // Exit if PIN is incomplete
    }

    try {
      // Retrieve email, password, and PIN from secure storage
      final storedEmail = await _storage.read(key: 'user_email');
      final storedPassword = await _storage.read(key: 'user_password');
      final storedPin = await _storage.read(key: 'user_pin');

      if (storedEmail == null || storedPassword == null || storedPin == null) {
        _showDialog(context, 'No user data found. Please sign up.');
        return;
      }

      // Check if the PIN matches the stored one
      if (pin == storedPin) {
        setState(() {
          _isPinCorrect = true; // Set color to green if PIN is correct
        });

        // Authenticate using stored email and password
        final cognitoUser = CognitoUser(storedEmail, _userPool);
        final authDetails = AuthenticationDetails(
          username: storedEmail,
          password: storedPassword,
        );

        final session = await cognitoUser.authenticateUser(authDetails);

        // Check if the session is valid and store the ID token
        if (session?.isValid() ?? false) {
          // Safely access the idToken as a String
          final idToken = session?.idToken?.getJwtToken();
          if (idToken != null) {
            // Store the ID token securely
            await _storage.write(key: 'id_token', value: idToken);
          }

          // Call the API after successful login
          await _callApiAfterLogin(storedEmail);

          // Navigate to the home screen
          Navigator.pushReplacementNamed(
              context, '/home', arguments: storedEmail);
        } else {
          _showDialog(context, 'Login failed. Try again.');
        }
      } else {
        setState(() {
          _isPinCorrect = false; // Change input fields to red if PIN is incorrect
        });
      }
    } catch (e) {
      _showDialog(context, 'Error: $e');
    }
  }

  // Function to call the API after successful login
Future<void> _callApiAfterLogin(String email) async {
  try {
    // Create a URL with query parameters directly embedded in the URL
    var request = http.Request(
      'POST', 
      Uri.parse('https://88cdecusie.execute-api.ap-south-1.amazonaws.com/light/getuser?userEmail=$email') // Add email directly in the URL
    );

    // Set any headers if necessary
    request.headers.addAll({
      'Content-Type': 'application/json', // Optional for POST requests
    });

    // Send the request and get the response
    final response = await request.send();

    // Check the response status
    if (response.statusCode == 200) {
      print('API Call Success');
    } else {
      print('API Call Failed: ${response.statusCode}');
    }
  } catch (e) {
    print('API Call Error: $e');
  }
}


  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Custom keypad builder
  Widget _buildPinKeyPad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
      ),
      itemCount: 12, // Including 0 at the end
      itemBuilder: (context, index) {
        String digit = '';
        if (index < 9) {
          digit = (index + 1).toString();
        } else if (index == 9) {
          digit = '0';
        } else if (index == 10) {
          digit = '←'; // Backspace button
        } else {
          return SizedBox.shrink();
        }

        return InkWell(
          onTap: () {
            if (digit == '←' && pin.isNotEmpty) {
              setState(() {
                pin = pin.substring(0, pin.length - 1);
              });
            } else if (digit != '←') {
              _onPinDigitPressed(digit);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(8),
            child: Center(
              child: digit == '←'
                  ? Icon(Icons.backspace, size: 24, color: Colors.blue)
                  : Text(
                      digit,
                      style: const TextStyle(fontSize: 24),
                    ),
            ),
          ),
        );
      },
    );
  }
}
