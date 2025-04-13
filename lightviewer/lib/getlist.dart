import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'download.dart';

class FileListWidget extends StatefulWidget {
  const FileListWidget({Key? key}) : super(key: key);

  @override
  FileListWidgetState createState() => FileListWidgetState();
}

class FileListWidgetState extends State<FileListWidget> {
  List<String> fileNames = [];
  final secureStorage = FlutterSecureStorage();

  // Fetch file list from AWS S3 using user_email as a query parameter
  Future<void> fetchS3FileList() async {
    const apiUrl = "https://88cdecusie.execute-api.ap-south-1.amazonaws.com/light/getlist"; // Replace with your actual API URL

    try {
      // Retrieve the user_email from secure storage
      String? userEmail = await secureStorage.read(key: 'user_email');
      if (userEmail == null || userEmail.isEmpty) {
        print("User email not found!");
        return;
      }

      // Append user_email as a query parameter
      final uri = Uri.parse(apiUrl).replace(queryParameters: {'prefix': userEmail});
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Parse the JSON response
        List<dynamic> fileList = json.decode(response.body);
        setState(() {
          fileNames = List<String>.from(fileList); // Store filenames in a list
        });
      } else {
        print("Failed to fetch files. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }

  // Public method to refresh file list
  void refreshFiles() {
    fetchS3FileList();
  }

  @override
  void initState() {
    super.initState();
    fetchS3FileList(); // Fetch the file list when the widget is first created
  }

  // Function to delete file from S3
  Future<void> deleteFile(String fileName) async {
    try {
      // Retrieve the user_email from secure storage
      String? userEmail = await secureStorage.read(key: 'user_email');
      if (userEmail == null || userEmail.isEmpty) {
        print("User email not found!");
        return;
      }

      final Uri url = Uri.parse("https://88cdecusie.execute-api.ap-south-1.amazonaws.com/light/delete?filename=$fileName&prefix=$userEmail"); // Include prefix in delete request

      var request = http.Request('DELETE', url);

      // Send the delete request
      http.StreamedResponse response = await request.send();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted successfully.'),
        ),
      );

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final decodedResponse = jsonDecode(responseBody);
        print("Success: ${decodedResponse['message']}");
        // Refresh the file list after deleting
        fetchS3FileList();
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Exception occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return fileNames.isEmpty
        ? Center(child: CircularProgressIndicator()) // Show loading indicator
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true, // Ensures the GridView wraps its content
              physics: AlwaysScrollableScrollPhysics(), // Enables scroll behavior
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two items per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2, // Adjusts the aspect ratio of each grid item
              ),
              itemCount: fileNames.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 8, // Added elevation to the cards
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 8.0), // Reduced padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fileNames[index],
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 16, // Increased font size for better readability
                              fontWeight: FontWeight.bold, // Bold text for emphasis
                              color: Colors.black87, // Darker color for better contrast
                            ),
                            overflow: TextOverflow.ellipsis, // Handles long filenames
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert, color: Colors.deepPurple), // Icon color matching the theme
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return ListView(
                                  shrinkWrap: true,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.download, color: Colors.green),
                                      title: Text('Download'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        // Add your download logic here
                                        FileDownloader.downloadFile(fileNames[index]);

                                        // Show a SnackBar with the message
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${fileNames[index]} was saved'),
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete'),
                                      onTap: () {
                                        Navigator.pop(context); // Close the current popup (if this is in a modal sheet)
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Confirm Deletion'),
                                              content: Text('Do you really want to delete the file?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context); // Close the dialog without action
                                                  },
                                                  child: Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context); // Close the dialog
                                                    deleteFile(fileNames[index]); // Delete the file
                                                  },
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }
}
