import 'dart:io';
import 'dart:math';
import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:github/github.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// extension to call [uploadToGitHub]
extension FeedbackGitHub on FeedbackController {
  /// Check [uploadToGitHub] for more documentation
  void showAndUploadToGitHub({
    required String repoUrl,
    required String gitHubToken,
    List<String> labels = const ['feedback'],
    bool packageInfo = true,
    bool deviceInfo = true,
    String? extraData,
    Reference? imageRef,
    void Function(Issue)? onSucces,
    void Function(Object error)? onError,
  }) {
    show((feedback) async {
      hide(); // don't block the ui
      try {
        final issue = await uploadToGitHub(
          repoUrl: repoUrl,
          gitHubToken: gitHubToken,
          title:
              '[FEEDBACK] ${feedback.text.substring(0, min(100, feedback.text.length))}',
          feedbackText: feedback.text,
          screenshot: feedback.screenshot,
          labels: labels,
          packageInfo: packageInfo,
          deviceInfo: deviceInfo,
          extraData: extraData,
          imageRef: imageRef,
        );
        onSucces?.call(issue);
      } catch (e) {
        onError?.call(e);
      }
    });
  }
}

/// Store image in firebase storage and create GitHub issue with feedback
///
/// [repoUrl] is the URL of the GitHub repository.
///
/// [gitHubToken] is the token used for GitHub authentication.
///
/// [title] is the title of the issue created
///
/// [feedbackText] is the main content of the feedback.
///
/// [screenshot] the screenshot
///
/// [labels] are the labels to be applied to the GitHub issue. Default is `['feedback']`.
///
/// [packageInfo] indicates whether to include package information. Default is `true`.
///
/// [deviceInfo] indicates whether to include device information. Default is `true`.
///
/// [extraData] is any additional data to be included.
///
/// [imageRef] optional reference if you want to store the image somewhere else than default /user-feedback-images/filename
Future<Issue> uploadToGitHub({
  required String repoUrl,
  required String gitHubToken,
  required String title,
  required String feedbackText,
  required Uint8List screenshot,
  List<String> labels = const ['feedback'],
  bool packageInfo = true,
  bool deviceInfo = true,
  String? extraData,
  Reference? imageRef,
}) async {
  final imageUrl = await uploadImageToStorage(screenshot, imageRef);

  final String package = packageInfo
      ? "## Package\n${Platform.operatingSystem}\n${_formatKeys((await PackageInfo.fromPlatform()).data, [
              "version",
              "buildNumber",
              "installerStore"
            ])}\n\n"
      : "";

  final String device = deviceInfo
      ? "## Device\n${_formatKeys((await DeviceInfoPlugin().deviceInfo).data, [
              "model",
              "brand",
              "version",
              "systemVersion",
              "isPhysicalDevice"
            ])}\n\n"
      : "";

  final String extra = extraData != null ? '## Extra\n$extraData' : "";

  final image = imageUrl != null
      ? '[Download Image]($imageUrl)\n\n'
      : "no image attached";

  final body = '$feedbackText \n\n $image $package $device $extra';

  return createGithubIssue(
      repoUrl: repoUrl,
      title: title,
      body: body,
      gitHubToken: gitHubToken,
      labels: labels);
}

/// Upload image to firebase storage and return the download url
Future<String?> uploadImageToStorage(
    Uint8List imageData, Reference? imageRef) async {
  try {
    final filename = '${const Uuid().v4()}.png'; // the plugin returns only pngs
    final imgRef = imageRef ??
        FirebaseStorage.instance.ref().child("user-feedback-images/$filename");

    await imgRef.putData(imageData);

    return await imgRef.getDownloadURL();
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

/// Create issue on the specified repo
Future<Issue> createGithubIssue({
  required String repoUrl,
  required String title,
  required String body,
  required String gitHubToken,
  List<String> labels = const ['feedback'],
}) async {
  final github = GitHub(auth: Authentication.withToken(gitHubToken));
  // https://github.com/tempo-riz/feedback_github or https://github.com/tempo-riz/feedback_github.git -> temporiz / feedback_github
  final split = repoUrl.split("/");
  final owner = split[split.length - 2];
  final name = split[split.length - 1]
      .split(".")
      .first; //remove .git in case there is any

  RepositorySlug slug = RepositorySlug(owner, name);

  IssueRequest issue = IssueRequest(
    title: title,
    body: body,
    labels: labels,
  );
  return github.issues.create(slug, issue);
}

String _formatKeys(Map<String, dynamic> map, List<String> keys) {
  return keys
      .map((key) => map.containsKey(key) && map[key] != null
          ? "$key: ${map[key].toString()}"
          : null)
      .where((value) => value != null)
      .join("\n");
}
