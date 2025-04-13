import 'package:flutter/material.dart';
import 'getlist.dart'; // Import the getlist.dart file
import 'upload.dart'; // Import the upload.dart file

class CloudWidget extends StatefulWidget {
  @override
  _CloudWidgetState createState() => _CloudWidgetState();
}

class _CloudWidgetState extends State<CloudWidget> {
  // Key for triggering refresh in FileListWidget
  final GlobalKey<FileListWidgetState> _fileListKey = GlobalKey<FileListWidgetState>();

  // Function to refresh the file list
  void _refreshFileList() {
    _fileListKey.currentState?.refreshFiles();
  }

  // Function to show the upload widget when the floating button is clicked
  void _showUploadWidget() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow resizing based on keyboard visibility
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)), // Rounded top corners
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4, // Start at 40% of screen height
          minChildSize: 0.2, // Minimum height (20% of screen height)
          maxChildSize: 0.8, // Maximum height (80% of screen height)
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color of the modal
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)), // Rounded corners
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8, // Constrain the height
                    ),
                    child: UploadWidget(
                      onFileUploaded: _refreshFileList, // Refresh the list after successful upload
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  
      body: Column(
        children: [
          // Expanded widget to ensure GridView takes available space
          Expanded(
            child: FileListWidget(
              key: _fileListKey, // Assign the GlobalKey for refreshing
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadWidget, // Call the upload function
        child: Icon(Icons.add, size: 35.0), // Larger icon for better visibility
        backgroundColor: Colors.deepPurple, // Custom background color for the FAB
        elevation: 8.0, // Add shadow for 3D effect
        tooltip: 'Upload File', // Tooltip for better user experience
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Bottom-right position
    );
  }
}
