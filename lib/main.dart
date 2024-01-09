// ignore_for_file: avoid_print

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MainApp());
}

// Photo URL
String photoUrl = 'https://www.gstatic.com/webp/gallery/1.jpg';
// Your album name
const albumName = 'my album';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Save Image to Album Sample'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Album Name: "$albumName"'),
              const SizedBox(height: 10,),
              const Text('Save Image Name: "Time Stamp"'),
              const SizedBox(height: 10,),
              ElevatedButton.icon(
                onPressed: () {
                  saveImage();
                },
                icon: const Icon(Icons.save_alt),
                label: const Text('Save image'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  PhotoManager.openSetting();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveImage() async {
    try {
      final response = await http.get(Uri.parse(photoUrl));
      final tempDir = await getTemporaryDirectory();

      // create save directory
      if (Platform.isAndroid) {
        final picturesPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_PICTURES,
        );
        final albumPath = '$picturesPath/$albumName';
        // If directory does not exist, create directory before writing.
        await Directory(albumPath).create(recursive: true);
      }

      final now = DateTime.now();
      DateFormat outputFormat = DateFormat('yyyy-MM-dd_HH-mm_ssS');
      final fileName = '${outputFormat.format(now)}.jpg';
      print('file name: $fileName');

      final file = File('${tempDir.path}/$fileName')..writeAsBytesSync(response.bodyBytes);
      print('temp file path: ${file.path}');
      final permissionState = await PhotoManager.requestPermissionExtend();
      if (!permissionState.isAuth) {
        Fluttertoast.showToast(msg: 'Please allow access and try again.');
        return;
      }

      // save image
      final assetEntity = await PhotoManager.editor.saveImageWithPath(
        file.path,
        title: fileName,
        relativePath: Platform.isAndroid ? 'Pictures/$albumName' : albumName,
      );
      print('assetEntity: $assetEntity');

      // iOS needs tagging to image.
      if (Platform.isIOS) {
        final paths = await PhotoManager.getAssetPathList();
        var assetPathEntity = paths.firstWhereOrNull((e) => e.name == albumName);
        // If album does not exist, you also need to use the createAlbum method before copying.
        assetPathEntity ??= await PhotoManager.editor.darwin.createAlbum(albumName);
        await PhotoManager.editor.copyAssetToPath(
          asset: assetEntity!,
          pathEntity: assetPathEntity!,
        );
      }
      Fluttertoast.showToast(msg: 'Success! saved image as $fileName');

      // clear cache
      file.deleteSync(recursive: true);
      print('completed!');

    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'error: $e');
    }
  }
}
