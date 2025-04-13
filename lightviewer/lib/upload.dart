import 'dart:convert'; // Import for base64 encoding
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'getlist.dart'; // Import for refreshing the file list
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class UploadWidget extends StatefulWidget {
  final Function? onFileUploaded; // Callback for notifying upload completion

  const UploadWidget({Key? key, this.onFileUploaded}) : super(key: key);

  @override
  _UploadWidgetState createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<UploadWidget> {
  String? fileName;
  String? selectedFilePath;
  bool isButtonEnabled = false;
  String uploadStatus = '';
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? prefix; // New variable to store the prefix

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String? userEmail;

  // Fetch the user email stored in secure storage
  Future<void> _getUserEmail() async {
    String? email = await secureStorage.read(key: 'user_email');
    setState(() {
      userEmail = email;
      prefix = userEmail ?? 'default_prefix'; // Use email as prefix or set a default
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserEmail();  // Fetch the email when the widget is loaded
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
        fileName = result.files.single.name;
        isButtonEnabled = fileName != null && selectedFilePath != null;
      });
    }
  }

  void uploadFile() {
    if (fileName != null && selectedFilePath != null) {
      uploadFileToLambda(selectedFilePath!, fileName!);
    }
  }

  Future<void> uploadFileToLambda(String filePath, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Convert the file to a base64 string
      String base64FileContent = await _encodeFileToBase64(filePath);

      // Use the prefix parameter to form the API URL
      String apiUrl = 'https://88cdecusie.execute-api.ap-south-1.amazonaws.com/light/upload?filename=$fileName&action=upload&prefix=$prefix';
      var headers = {
        'Content-Type': 'application/json',
      };

      var request = http.Request('POST', Uri.parse(apiUrl));
      request.body = json.encode({
        "body": base64FileContent,
      });
      request.headers.addAll(headers);

      var response = await request.send();

      response.stream.listen(
        (data) {
          setState(() {
            _uploadProgress = (data.length / response.contentLength!) * 100;
          });
        },
        onDone: () async {
          if (response.statusCode == 200) {
            String responseBody = await response.stream.bytesToString();
            setState(() {
              uploadStatus = 'File uploaded successfully: $responseBody';
              _isUploading = false;
              _uploadProgress = 100;
            });
            // Notify parent widget about the upload
            widget.onFileUploaded?.call();
          } else {
            setState(() {
              uploadStatus = 'Failed to upload file. Error: ${response.reasonPhrase}';
              _isUploading = false;
              _uploadProgress = 0.0;
            });
          }
        },
        onError: (e) {
          setState(() {
            uploadStatus = 'Error occurred during file upload: $e';
            _isUploading = false;
            _uploadProgress = 0.0;
          });
        },
      );
    } catch (e) {
      setState(() {
        uploadStatus = 'Error occurred during file upload: $e';
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // Function to encode the file into base64
  Future<String> _encodeFileToBase64(String filePath) async {
    // Read the file as bytes
    final bytes = await File(filePath).readAsBytes();
    // Convert bytes to base64 string
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload to Cloud"),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true, // Allows the widget to adjust when the keyboard appears
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: Text('Pick File'),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter file name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  fileName = value;
                  isButtonEnabled = fileName != null && selectedFilePath != null;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter prefix (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  prefix = value; // Update prefix value
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              selectedFilePath != null ? 'Selected file: $fileName' : 'No file selected',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isButtonEnabled ? uploadFile : null,
              child: Text('Upload'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(isButtonEnabled ? Colors.blue : Colors.grey),
              ),
            ),
            SizedBox(height: 20),
            Text(
              uploadStatus,
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            if (_isUploading) ...[
              SizedBox(height: 20),
              LinearProgressIndicator(
                value: _uploadProgress / 100,
                minHeight: 10,
                color: _uploadProgress == 100 ? Colors.green : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
