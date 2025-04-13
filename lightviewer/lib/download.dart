import 'dart:io';
import 'dart:convert';  // Import for base64 decoding
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FileDownloader {
  static Future<void> downloadFile(String filename) async {
    // Fetch user email from secure storage
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? userEmail = await secureStorage.read(key: 'user_email');

    // Use the prefix (user email) or set a default
    String prefix = userEmail ?? 'default_prefix';

    // Construct the URL with the prefix
    String url = 'https://88cdecusie.execute-api.ap-south-1.amazonaws.com/light/download?filename=$filename&action=download&prefix=$prefix';

    try {
      // Get the external storage directory
      Directory? externalDir = await getExternalStorageDirectory();

      if (externalDir != null) {
        // Create the "downloads" folder inside external storage
        Directory downloadsDir = Directory('${externalDir.path}/downloads');
        if (!downloadsDir.existsSync()) {
          downloadsDir.createSync(recursive: true); // Ensure the directory exists
        }

        // Construct the full file path
        String filePath = '${downloadsDir.path}/$filename';

        // Make HTTP GET request
        var response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          // Decode the base64-encoded file content (if it is base64)
          Map<String, dynamic> responseBody = json.decode(response.body);
          String? base64FileContent = responseBody['file_content'];

          if (base64FileContent != null) {
            // Decode the Base64 string
            var decodedBytes = base64Decode(base64FileContent);
            
            // Save the decoded file to the specified path
            File file = File(filePath);
            await file.writeAsBytes(decodedBytes);
            print("File downloaded and saved at $filePath");
          } else {
            // If no Base64 content, directly save the file (may be raw bytes)
            var decodedBytes = response.bodyBytes;
            File file = File(filePath);
            await file.writeAsBytes(decodedBytes);
            print("File downloaded and saved at $filePath");
          }
        } else {
          print('Failed to download file: ${response.reasonPhrase}');
        }
      } else {
        print('Could not get external storage directory.');
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
  }
}
