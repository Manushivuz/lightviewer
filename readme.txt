<----LightViewer---->

What is it?
It's a mobile app developed using Flutter that uses AWS resources for document storage, like any other apps.

What is new/different ?
"Semi-Verification" feature: Any user(admin) can mark a file as "signed" using their key and share the file through any platform, the same can be verified by the user(client) on the other side. It ensures authentication and file integrity.

Steps to debug in desktop:-
Tools: Android Studio, Suitable IDE (VS Code) & Install Flutter Plugin

- Create a default flutter project  (ex:- "default")
- Extract the "project" folder
- Copy the ".dart_tool" and "build" folder from "default" and paste in "project"
- Import the "project" folder in Android Studio
- Ensure all the dependencies in "pubspec.yaml" is installed
- Run

Directly run the app in android phone:-
- In case the app doesnt load during signup,it would mean the AWS hosting is removed, contact the dev for renewal.