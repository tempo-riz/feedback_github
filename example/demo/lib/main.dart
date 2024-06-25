import 'package:feedback_github/feedback_github.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:example/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // don't forget to wrap Material app with BetterFeedback widget :
  runApp(BetterFeedback(
    child: App(),
  ));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Demo',
        home: Scaffold(
          appBar: AppBar(title: Text("Demo")),
          body: Center(
              child: ElevatedButton.icon(
            icon: Icon(Icons.feedback),
            label: Text("Send feedback"),
            onPressed: () {
              // you can check how it will look here https://github.com/tempo-riz/dummy-repo/issues/2
              BetterFeedback.of(context).showAndUploadToGitHub(
                  repoUrl: "https://github.com/tempo-riz/dummy-repo",
                  // Save it in an environment variable :)
                  gitHubToken: dotenv.get("GITHUB_ISSUE_TOKEN"),
                  // those are optionals (default values)
                  labels: ['feedback'],
                  packageInfo: true,
                  deviceInfo: true,
                  extraData: "Some extra data you want to add in the issue",
                  // imageRef: // another firebase storage ref to store the image
                  onSucces: (issue) => print("succes !"),
                  onError: (error) => print("failed :/ $error"));
            },
          )),
        ));
  }
}
