import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MaterialApp(home: MergedApp(), debugShowCheckedModeBanner: false));
}

class MergedApp extends StatefulWidget {
  @override
  State<MergedApp> createState() => MergedAppState();
}

class MergedAppState extends State<MergedApp> {
  File? pickedFile;
  VideoPlayerController? controller;
  String status = "Video Select Kara";
  bool processing = false;
  bool showComparison = true;
  double previewProgress = 0;
  double convertProgress = 0;

  double focusFilter = 50;
  double fourKFilter = 70;
  double whitening = 25;
  double brilliance = 20;
  double sharpen = 60;
  String selectedMode = "Devi Glow";
  double intensity = 40;
  String selectedCategory = "Cinematic";
  String selectedFilter = "Oppenheimer";

  final categories = {
    "Cinematic": ["Green Orange", "Sicily", "Oppenheimer", "Freedom"],
    "Quality": ["Quality Boost", "HD Skin"],
    "Glow": ["Film CCD", "Glow"],
    "Vintage": ["Antique", "Retro Film"],
    "Night": ["Lunar Night", "Midnight"],
  };

  Future<void> pick() async {
    await Permission.storage.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r != null) {
      pickedFile = File(r.files.single.path!);
      controller?.dispose();
      controller = VideoPlayerController.file(pickedFile!);
      await controller!.initialize();
      controller!.setLooping(true);
      controller!.play();
      Timer.periodic(Duration(milliseconds: 200), (t) {
        if (controller != null && controller!.value.isInitialized) {
          setState(() {
            var dur = controller!.value.duration.inMilliseconds;
            if (dur == 0) dur = 1;
            previewProgress = controller!.value.position.inMilliseconds / dur;
          });
        }
      });
      setState(() {
        status = "Ready";
      });
    }
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() {
      processing = true;
      convertProgress = 0.01;
    });

    FFmpegKitConfig.enableStatisticsCallback((s) {
      double p = 0;
      if (controller != null) {
        var dur = controller!.value.duration.inMilliseconds;
        if (dur == 0) dur = 1;
        p = s.getTime() / dur;
      }
      if (p > 0.99) p = 0.99;
      if (p < 0) p = 0;
      setState(() {
        convertProgress = p;
        status = "Converting";
      });
    });

    Directory d = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    String out = d.path + "/HATKE_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";

    double sharpVal = (sharpen + focusFilter) / 100 * 2.5;
    bool isPortrait = true;
    if (controller != null) {
      isPortrait = controller!.value.size.height > controller!.value.size.width;
    }

    String scalePart = "";
    if (isPortrait) {
      scalePart = "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,scale=2160:3840:flags=lanczos";
    } else {
      scalePart = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,scale=3840:2160:flags=lanczos";
    }

    String vf = scalePart + ",unsharp=5:5:" + sharpVal.toString() + ":5:5:0,eq=contrast=1.2:brightness=0.03:saturation=1.4";

    String inputPath = pickedFile!.path;
    String cmd = "-y -i '" + inputPath + "' -vf \"" + vf + "\" -c:v libx264 -preset medium -crf 18 -c:a aac '" + out + "'";

    var session = await FFmpegKit.execute(cmd);
    FFmpegKitConfig.enableStatisticsCallback(null);
    var rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      setState(() {
        convertProgress = 1.0;
        processing = false;
        status = "DONE Saved " + out;
      });
    } else {
      setState(() {
        processing = false;
        status = "Failed";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text("HATKE 4K CLEAR", style: TextStyle(fontSize: 14)),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: processing ? null : pick,
              child: Text("SELECT VIDEO"),
            ),
            if (controller != null && controller!.value.isInitialized)
              Column(
                children: [
                  AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showComparison = !showComparison;
                          });
                        },
                        child: Text(showComparison ? "SINGLE" : "COMPARE"),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: intensity,
                          min: 30,
                          max: 50,
                          onChanged: (v) {
                            setState(() {
                              intensity = v;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  LinearProgressIndicator
