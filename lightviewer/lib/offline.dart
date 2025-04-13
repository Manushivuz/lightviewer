import 'dart:io'; // For file handling
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // For accessing external storage paths
import 'package:open_file/open_file.dart'; // For opening files

class OfflineWidget extends StatefulWidget {
  @override
  _OfflineWidgetState createState() => _OfflineWidgetState();
}

class _OfflineWidgetState extends State<OfflineWidget> {
  List<FileSystemEntity> files = []; // To store the list of files
  Directory? downloadsDir; // To hold the downloads directory

  @override
  void initState() {
    super.initState();
    _initializeDownloadsDirectory(); // Initialize the downloads directory
  }

  Future<void> _initializeDownloadsDirectory() async {
    try {
      // Get the external storage directory
      Directory? externalDir = await getExternalStorageDirectory();

      if (externalDir != null) {
        // Create the "downloads" folder inside external storage
        Directory dir = Directory('${externalDir.path}/downloads');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        // Set the directory and list the files
        setState(() {
          downloadsDir = dir;
          files = dir.listSync();
        });
      }
    } catch (e) {
      print('Error initializing downloads directory: $e');
    }
  }

  // Refresh the file list
  Future<void> _refreshFiles() async {
    if (downloadsDir != null) {
      setState(() {
        files = downloadsDir!.listSync();
      });
    }
  }

  // Open the selected file
  void _openFile(File file) {
    OpenFile.open(file.path);
  }

  // Handle rename action
  void _renameFile(File file) {
    TextEditingController _controller = TextEditingController();
    _controller.text = file.uri.pathSegments.last; // Pre-fill with current file name

    // Show a dialog for renaming the file
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Rename File', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'New File Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Rename', style: TextStyle(color: Colors.green)),
              onPressed: () async {
                String newName = _controller.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    String newPath = '${file.parent.path}/$newName';
                    // Rename the file
                    await file.rename(newPath);

                    // Refresh the file list after renaming
                    _refreshFiles();

                    // Close the dialog and show success message
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File renamed to $newName')),
                    );
                  } catch (e) {
                    // Handle error in renaming
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error renaming the file: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Handle delete action
  void _deleteFile(File file) async {
    try {
      // Deleting the file
      await file.delete();

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.path.split('/').last} deleted successfully.'),
        ),
      );

      // Refresh the file list to remove the deleted file
      _refreshFiles();
    } catch (e) {
      // Handle error in deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting the file: $e'),
        ),
      );
    }
  }

  // Handle details action
  void _viewFileDetails(File file) async {
    // Fetch file stats
    FileStat fileStat = await file.stat();
    String size = (fileStat.size / 1024).toStringAsFixed(2) + ' KB'; // Size in KB
    String createdAt = fileStat.changed.toString();
    String modifiedAt = fileStat.modified.toString();
    String filePath = file.path; // File path

    // Show file details in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File Details', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('File Path: $filePath'),
              Text('Size: $size'),
              Text('Created At: $createdAt'),
              Text('Modified At: $modifiedAt'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: files.isEmpty
          ? Center(
              child: Text(
                'No files found in the downloads folder.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: files.length,
              itemBuilder: (context, index) {
                FileSystemEntity entity = files[index];
                if (entity is File) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.insert_drive_file, color: Colors.deepPurple),
                      title: Text(
                        entity.path.split('/').last, // Extract the filename
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Tap to open', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert),
                        onSelected: (String value) {
                          switch (value) {
                            case 'rename':
                              _renameFile(entity);
                              break;
                            case 'delete':
                              _deleteFile(entity);
                              break;
                            case 'details':
                              _viewFileDetails(entity);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return ['rename', 'delete', 'details']
                              .map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice.capitalize(), style: TextStyle(fontSize: 14)),
                            );
                          }).toList();
                        },
                      ),
                      onTap: () => _openFile(entity), // Open the file on tap
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
    );
  }
}

// Extension to capitalize text for menu items
extension StringCasingExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + this.substring(1);
  }
}
