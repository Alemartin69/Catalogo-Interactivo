import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String? thumbnailFromUrl(String url) {
  // YouTube thumbnail
  final ytMatch = RegExp(
          r'(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})')
      .firstMatch(url);
  if (ytMatch != null) {
    return 'https://img.youtube.com/vi/${ytMatch.group(1)}/hqdefault.jpg';
  }
  return null;
}
