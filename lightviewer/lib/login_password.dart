import 'package:flutter/material.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signup.dart';  // Make sure you have the signup screen
import 'login.dart';
import 'package:restart_app/restart_app.dart'; // Import the restart_app package

class LoginPasswordWidget extends StatefulWidget {
  @override
  _LoginPasswordWidgetState createState() => _LoginPasswordWidgetState();
}

class _LoginPasswordWidgetState extends State<LoginPasswordWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isAccountVerified = false;

  final CognitoUserPool _cognitoUserPool = CognitoUserPool(
    'ap-south-1_gScvuXkq9', // Your user pool ID
    '5iehem84fdr043cas2l3vh4hhf', // Your client ID
  );

  String _errorMessage = '';
  bool _isPinSet = false;

  // Check if the user has already set a PIN
  Future<void> _checkIfPinSet(String username) async {
    try {
      String? storedPin = await _secureStorage.read(key: 'user_pin');
      if (storedPin != null && storedPin.isNotEmpty) {
        setState(() {
          _isPinSet = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error reading PIN: $e';
      });
    }
  }

  // Function to authenticate user
  Future<void> _authenticateUser() async {
    final username = _emailController.text;
    final password = _passwordController.text;

    final cognitoUser = CognitoUser(username, _cognitoUserPool);
    final authDetails = AuthenticationDetails(
      username: username,
      password: password,
    );

    try {
      final session = await cognitoUser.authenticateUser(authDetails);
      _isAccountVerified = true;
      setState(() {
        _errorMessage = '';
      });

      // Store email and password securely
      await _secureStorage.write(key: 'user_email', value: username);
      await _secureStorage.write(key: 'user_password', value: password);

      _checkIfPinSet(username); // Check if user has already set PIN
    } catch (e) {
      print('Authentication error: $e');
      setState(() {
        _errorMessage = 'Authentication failed: $e';
      });
    }
  }

  // Set the PIN if not already set
  Future<void> _setPin() async {
    final pin = _pinController.text;

    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() {
        _errorMessage = 'PIN must be exactly 4 numeric digits.';
      });
      return;
    }

    try {
      // Save the PIN securely
      await _secureStorage.write(key: 'user_pin', value: pin);

      setState(() {
        _isPinSet = true;
        _errorMessage = '';
      });
      print('PIN set successfully!');
    } catch (e) {
      print('Error saving PIN: $e');
      setState(() {
        _errorMessage = 'Failed to save PIN.';
      });
    }
  }

  // Navigate to Signup page
  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpWidget()),  // Ensure you have SignupWidget
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.orange, // Orange background for the app bar
      ),
      body: SingleChildScrollView( // Added to allow scrolling when keyboard is visible
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Email Input Field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.orange),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Password Input Field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.orange),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Login Button
            ElevatedButton(
              onPressed: _authenticateUser,
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Button color
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),

            // Error Message Display
            if (_errorMessage.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ],

            // Account Verified Message
            if (_isAccountVerified) ...[
              SizedBox(height: 20),
              Text(
                'Verified Account. Set up Your PIN',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ],

            // PIN Setup Logic
            if (_isPinSet) ...[
              Text('PIN is already set. Proceed to the app.'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isPinSet = false;
                    _errorMessage = '';
                  });

                  // Restart the app after refreshing the state
                  Restart.restartApp();
                },
                child: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Button color
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ] else ...[
              // PIN Setup Form
              SizedBox(height: 40),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'Set 4-digit PIN',
                  labelStyle: TextStyle(color: Colors.orange),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _setPin,
                child: Text('Set PIN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Button color
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],

            SizedBox(height: 20),

            // Signup Button
            TextButton(
              onPressed: _navigateToSignup,
              child: Text(
                "Don't have an account? Signup",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
