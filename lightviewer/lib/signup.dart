import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'login.dart'; // Import login.dart

class SignUpWidget extends StatefulWidget {
  @override
  _SignUpWidgetState createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _confirmationCodeController = TextEditingController();
  final _pinController = TextEditingController();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Cognito User Pool configuration
  final CognitoUserPool _cognitoUserPool = CognitoUserPool(
    'ap-south-1_gScvuXkq9', // Your user pool ID
    '5iehem84fdr043cas2l3vh4hhf', // Your client ID
  );

  bool _isCodeSent = false;
  String _errorMessage = '';

  Future<void> signUp() async {
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    final userAttributes = [
      AttributeArg(name: 'email', value: email),
    ];

    final cognitoUser = CognitoUser(username, _cognitoUserPool);
    try {
      final signUpResult = await _cognitoUserPool.signUp(username, password,
          userAttributes: userAttributes);
      print('Sign up success: $signUpResult');
      setState(() {
        _isCodeSent = true;
        _errorMessage = '';
      });
    } catch (e) {
      print('Sign up error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> confirmSignUp() async {
    final cognitoUser = CognitoUser(_usernameController.text, _cognitoUserPool);
    final confirmationCode = _confirmationCodeController.text;
    bool registrationConfirmed = false;
    try {
      registrationConfirmed = await cognitoUser.confirmRegistration(confirmationCode);
      print('Confirmation success: $registrationConfirmed');
      if (registrationConfirmed) {
        await _setupPIN(); // Call PIN setup after confirmation
      }
    } catch (e) {
      print('Confirmation error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _setupPIN() async {
    final pin = _pinController.text;
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() {
        _errorMessage = 'PIN must be exactly 4 numeric digits.';
      });
      return;
    }

    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      // Store encrypted email, password, and PIN
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_password', value: password);
      await _secureStorage.write(key: 'user_pin', value: pin);

      print('Email, Password, and PIN stored securely.');
      Navigator.pop(context); // Navigate back to login page
    } catch (e) {
      print('Error storing data: $e');
      setState(() {
        _errorMessage = 'Failed to store credentials securely.';
      });
    }
  }

  Future<void> resendConfirmationCode() async {
    final cognitoUser = CognitoUser(_usernameController.text, _cognitoUserPool);
    try {
      await cognitoUser.resendConfirmationCode();
      print('Confirmation code resent');
      setState(() {
        _errorMessage = '';
      });
    } catch (e) {
      print('Error resending code: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700, // Matching the login style
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Input fields with custom decoration
              _buildInputField(_usernameController, 'Username'),
              SizedBox(height: 20),
              _buildInputField(_emailController, 'Email ID'),
              SizedBox(height: 20),
              _buildInputField(_passwordController, 'Password', obscureText: true),
              SizedBox(height: 20),
              _buildInputField(_confirmPasswordController, 'Confirm Password', obscureText: true),
              SizedBox(height: 20),

              // PIN field and buttons
              if (!_isCodeSent) ...[
                _buildInputField(_pinController, 'Set 4-digit PIN', keyboardType: TextInputType.number),
                SizedBox(height: 20),
                _buildPrimaryButton('Sign Up', signUp),
              ],
              if (_isCodeSent) ...[
                _buildInputField(_confirmationCodeController, 'Confirmation Code'),
                SizedBox(height: 20),
                _buildPrimaryButton('Confirm Sign Up', confirmSignUp),
                TextButton(
                  onPressed: resendConfirmationCode,
                  child: Text('Resend Code', style: TextStyle(color: Colors.blue.shade700)),
                ),
              ],
              
              // Error message
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
              
              // Navigation back to login
              if (!_isCodeSent) ...[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Already have an account? Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Custom input field widget
  Widget _buildInputField(TextEditingController controller, String labelText,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.blue.shade700), // Label color
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade700),
        ),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.blue.shade50, // Light background color
      ),
    );
  }

  // Custom primary button widget
  Widget _buildPrimaryButton(String text, Function onPressed) {
    return ElevatedButton(
      onPressed: () => onPressed(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700, // Button color
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
