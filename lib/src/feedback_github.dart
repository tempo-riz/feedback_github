import 'dart:convert';
import 'dart:math';

import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// This is an extension to make it easier to call
/// [showAndUploadToGitHub].
extension FeedbackGitHub on FeedbackController {
  void showAndUploadToGitHub({
    required String repoUrl,
    required String gitHubToken,
    List<String>? labels,
  }) {
    show((feedback) => uploadToGitHub(
          repoUrl: repoUrl,
          gitHubToken: gitHubToken,
          title: '[FEEDBACK] ${feedback.text.substring(0, min(100, feedback.text.length))}',
          body: feedback.text,
          screenshot: feedback.screenshot,
          labels: labels,
        ));
  }
}

/// See [FeedbackGitHub.showAndUploadToGitHub].
Future<void> uploadToGitHub({
  required String repoUrl,
  required String gitHubToken,
  required String title,
  required String body,
  required Uint8List screenshot,
  List<String>? labels,
}) async {
  // TODO
}

/// upload image to firebase storage and return the download url
Future<String?> uploadImageToStorage(Uint8List data, String sourceName) async {
  try {
    final ext = sourceName.split('.').last;
    final filename = '${const Uuid().v4()}.$ext';
    final imageRef = FirebaseStorage.instance.ref().child("user-feedback-images/$filename");

    await imageRef.putData(data);

    return await imageRef.getDownloadURL();
  } catch (e) {
    print(e);
    return null;
  }
}

Future<void> createGithubIssue({required String title, required String body}) async {
  const token = String.fromEnvironment("GITHUB_ISSUE_TOKEN");

  final github = GitHub(auth: const Authentication.withToken(token));

  RepositorySlug slug = RepositorySlug.full('temporiz/reponame');

  IssueRequest issue = IssueRequest(
    title: title,
    body: body,
    labels: ['feedback'],
  );
  await github.issues.create(slug, issue);
}
