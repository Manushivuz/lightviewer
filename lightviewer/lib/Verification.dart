import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String? _selectedRole = 'Client';
  String? _selectedFile;
  bool isDocumentSigned = false;
  bool isDocumentVerified = false;
  List<String> fileList = [];
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> verifiedDocuments = [];

  List<String> roles = ['Client', 'Admin'];

  @override
  void initState() {
    super.initState();
    _loadFilesFromDownloads();
    _loadVerifiedDocuments();
  }

  // Load files from the downloads directory
  Future<void> _loadFilesFromDownloads() async {
    final directory = await getExternalStorageDirectory();
    final downloadsDir = Directory('${directory!.path}/downloads');

    if (await downloadsDir.exists()) {
      final files = downloadsDir.listSync();
      setState(() {
        fileList = files
            .whereType<File>()
            .map((file) => file.path.split('/').last)
            .toList();
      });
    }
  }

  // Load verified documents from the verified directory
  Future<void> _loadVerifiedDocuments() async {
    final directory = await getExternalStorageDirectory();
    final verifiedDir = Directory('${directory!.path}/verified');

    if (await verifiedDir.exists()) {
      final files = verifiedDir.listSync();
      setState(() {
        verifiedDocuments = files
            .whereType<File>()
            .map((file) {
              return {
                'filename': file.path.split('/').last,
                'verifier_email': 'example@domain.com', // You can adjust this as needed
                'is_verified': true,
              };
            })
            .toList();
      });
    }
  }

  Future<void> signDocument() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a file to sign.')),
      );
      return;
    }

    try {
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/downloads/$_selectedFile';
      final file = File(filePath);

      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File not found: $_selectedFile')),
        );
        return;
      }

      final fileBytes = await file.readAsBytes();
      final base64File = base64Encode(fileBytes);

      final verifierEmail = await storage.read(key: 'user_email');
      if (verifierEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Email not found in secure storage.')),
        );
        return;
      }

      final payload = {
        'action': 'putverify',
        'pdf_base64': base64File,
        'user_email': verifierEmail,
      };

      final response = await http.post(
        Uri.parse('https://88cdecusie.execute-api.ap-south-1.amazonaws.com/light/verification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        setState(() {
          isDocumentSigned = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document verified successfully!')),
        );
      } else {
        setState(() {
          isDocumentSigned = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> checkDocumentStatus() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a file to check status.')),
      );
      return;
    }

    try {
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/downloads/$_selectedFile';
      final file = File(filePath);

      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File not found: $_selectedFile')),
        );
        return;
      }

      final fileBytes = await file.readAsBytes();
      final base64File = base64Encode(fileBytes);

      final verifierEmail = await storage.read(key: 'user_email');
      if (verifierEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Email not found in secure storage.')),
        );
        return;
      }

      final payload = {
        'action': 'getverify',
        'pdf_base64': base64File,
        'user_email': verifierEmail,
      };

      final response = await http.post(
        Uri.parse('https://88cdecusie.execute-api.ap-south-1.amazonaws.com/light/verification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String verifierEmail = responseData['verifier_email'];
        final bool isVerified = responseData['is_verified'];

        setState(() {
          verifiedDocuments.add({
            'filename': _selectedFile,
            'verifier_email': verifierEmail,
            'is_verified': isVerified,
          });
          isDocumentVerified = isVerified;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document is verified!')),
        );
      } else {
        setState(() {
          isDocumentVerified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Role Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
	centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedRole,
              icon: Icon(Icons.arrow_downward, color: Colors.white),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(color: Colors.black),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue;
                  isDocumentSigned = false;
                  isDocumentVerified = false;
                  _selectedFile = null;
                });
              },
              items: roles.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: 18)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 30),
            if (_selectedRole == 'Admin')
              DropdownButton<String>(
                value: _selectedFile,
                hint: Text('Select a file to sign', style: TextStyle(fontSize: 16)),
                onChanged: (String? newFile) {
                  setState(() {
                    _selectedFile = newFile;
                    isDocumentSigned = false;
                  });
                },
                items: fileList.map<DropdownMenuItem<String>>((String file) {
                  return DropdownMenuItem<String>(
                    value: file,
                    child: Text(file, style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
              ),
            SizedBox(height: 20),
            if (_selectedRole == 'Admin' && _selectedFile != null)
              ElevatedButton(
                onPressed: signDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Sign this doc', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            if (_selectedRole == 'Admin')
              Text(
                isDocumentSigned ? 'Document Verified!' : 'Please verify a document.',
                style: TextStyle(fontSize: 16, color: isDocumentSigned ? Colors.green : Colors.red),
              ),
            if (_selectedRole == 'Client')
              DropdownButton<String>(
                value: _selectedFile,
                hint: Text('Select a file to check status', style: TextStyle(fontSize: 16)),
                onChanged: (String? newFile) {
                  setState(() {
                    _selectedFile = newFile;
                    isDocumentVerified = false;
                  });
                },
                items: fileList.map<DropdownMenuItem<String>>((String file) {
                  return DropdownMenuItem<String>(
                    value: file,
                    child: Text(file, style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
              ),
            SizedBox(height: 20),
            if (_selectedRole == 'Client' && _selectedFile != null)
              ElevatedButton(
                onPressed: checkDocumentStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Check Status', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            if (_selectedRole == 'Client')
              Text(
                isDocumentVerified ? 'Document Verified!' : 'Please check document status.',
                style: TextStyle(fontSize: 16, color: isDocumentVerified ? Colors.green : Colors.red),
              ),
            SizedBox(height: 20),
            Text('Verified Documents:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: verifiedDocuments.length,
                itemBuilder: (context, index) {
                  final document = verifiedDocuments[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(document['filename'], style: TextStyle(fontSize: 16)),
                      subtitle: Text('Verifier: ${document['verifier_email']}', style: TextStyle(fontSize: 14)),
                      trailing: Icon(
                        document['is_verified'] ? Icons.check_circle : Icons.cancel,
                        color: document['is_verified'] ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
