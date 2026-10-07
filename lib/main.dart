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
  @override State<MergedApp> createState() => MergedAppState();
}

class MergedAppState extends State<MergedApp> {
  File? pickedFile;
  VideoPlayerController? controller;
  String status = "Video Select Kara";
  bool processing = false;
  double progress = 0;

  double sharpen = 75;
  double intensity = 45;
  String selectedCategory = "Cinematic";
  List<String> selectedFilters = ["Retro Print"];

  final Map<String, List<String>> categories = {
    "Cinematic": ["Retro Print", "Badbunny", "Clear Sky", "Oppenheimer", "Wong Kar Wai", "Green Orange", "Freedom"],
    "Quality Enhance": ["Quality Boost", "HD Skin", "HD Uplight"],
    "Glow": ["Film CCD", "Glow", "Summer Ship", "Bright"],
    "Vintage": ["Antique", "Retro Film", "Universal S."],
    "Night": ["Lunar Night", "Midnight", "Green Yellow"],
  };

  // PREVIEW SATHI REAL MATRIX - ha app madhe disnar
  final Map<String, List<double>> previewMatrix = {
    "Retro Print": [1.2, 0.05, 0.0, 0, 10, 0.0, 1.1, 0.05, 0, 5, -0.2, 0.1, 0.9, 0, 0, 0,0,0,1,0],
    "Badbunny": [1.25, 0, 0, 0, 15, 0, 1.05, 0, 0, 8, 0, 0, 1.2, 0, 10, 0,0,0,1,0],
    "Clear Sky": [1.1, 0, 0, 0, 5, 0, 1.15, 0, 0, 10, 0, 0, 1.35, 0, 15, 0,0,0,1,0],
    "Oppenheimer": [1.3, 0.1, 0, 0, 0, 0.1, 0.9, 0, 0, -5, 0, 0, 0.8, 0, -10, 0,0,0,1,0],
    "Wong Kar Wai": [1.35, 0.1, -0.1, 0, 10, -0.1, 1.0, -0.1, 0, 0, -0.2, 0.1, 0.8, 0, -5, 0,0,0,1,0],
    "Green Orange": [1.4, 0.2, 0, 0, 10, 0.1, 1.0, 0, 0, 0, -0.3, 0, 0.7, 0, 0, 0,0,0,1,0],
    "Freedom": [1.15, 0, 0, 0, 15, 0, 1.15, 0, 0, 15, 0, 0, 1.15, 0, 15, 0,0,0,1,0],
    "Hasselblad 2": [1.2, 0, 0, 0, 8, 0, 1.2, 0, 0, 8, 0, 0, 1.2, 0, 8, 0,0,0,1,0],
    "Quality Boost": [1.1, 0, 0, 0, 8, 0, 1.1, 0, 0, 8, 0, 0, 1.1, 0, 8, 0,0,0,1,0],
    "Summer Ship": [1.05, 0.1, 0, 0, 20, 0, 1.2, 0.1, 0, 15, 0, 0, 0.95, 0, 0, 0,0,0,1,0],
    "Bright": [1.2, 0, 0, 0, 25, 0, 1.2, 0, 0, 25, 0, 0, 1.2, 0, 25, 0,0,0,1,0],
    "Universal S.": [1.3, 0.15, 0, 0, 5, 0.1, 1.0, 0, 0, 0, 0, 0, 0.75, 0, -5, 0,0,0,1,0],
    "Green Yellow": [1.1, 0.15, 0, 0, 5, 0.1, 1.25, 0, 0, 10, 0, 0, 0.8, 0, 0, 0,0,0,1,0],
  };

  // SAVE SATHI FFmpeg FILTER - toch effect video save hotana
  final Map<String, String> ffmpegMap = {
    "Retro Print": "colorbalance=gs=0.20:bs=-0.30:rs=0.20,eq=saturation=1.45:contrast=1.20:brightness=0.04",
    "Badbunny": "colorbalance=rs=0.25:bs=0.25,eq=saturation=1.35:contrast=1.25:brightness=0.06",
    "Clear Sky": "eq=saturation=1.6:contrast=1.30:brightness=0.05,colorbalance=bs=0.20:gs=0.10",
    "Oppenheimer": "eq=saturation=0.70:contrast=1.40:brightness=-0.02,curves=strong_contrast",
    "Wong Kar Wai": "curves=vintage,colorbalance=rs=0.30:gs=-0.15:bs=-0.25,eq=saturation=1.30:contrast=1.15",
    "Green Orange": "colorbalance=rs=0.40:gs=-0.15:bs=-0.40,eq=saturation=1.40:contrast=1.20",
    "Freedom": "eq=saturation=1.50:contrast=1.20:brightness=0.06",
    "Hasselblad 2": "eq=saturation=1.35:contrast=1.25:brightness=0.04,colorbalance=rs=0.10:gs=0.08",
    "Quality Boost": "eq=contrast=1.25:brightness=0.05:saturation=1.45,unsharp=5:5:1.2:5:5:0",
    "Summer Ship": "eq=brightness=0.10:saturation=1.60:contrast=1.15,colorbalance=gs=0.25",
    "Bright": "eq=brightness=0.18:saturation=1.70:contrast=1.10",
    "Universal S.": "eq=contrast=1.40:saturation=1.45,colorbalance=rs=0.45:ys=0.25,curves=vintage",
    "Green Yellow": "eq=contrast=1.25:saturation=1.30,colorchannelmixer=rr=1.15:gg=1.20:bb=0.85",
  };

  Future<void> pick() async {
    await Permission.storage.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r!= null) {
      pickedFile = File(r.files.single.path!);
      controller?.dispose();
      controller = VideoPlayerController.file(pickedFile!);
      await controller!.initialize();
      controller!.setLooping(true);
      controller!.play();
      Timer.periodic(Duration(milliseconds: 200), (t) {
        if (controller!= null && controller!.value.isInitialized) {
          var dur = controller!.value.duration.inMilliseconds;
          if (dur == 0) dur = 1;
          setState(() { progress = controller!.value.position.inMilliseconds / dur; });
        }
      });
      setState(() => status = "Ready");
    }
  }

  List<double> getCombinedMatrix() {
    List<double> base = [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0];
    for (var name in selectedFilters) {
      if (previewMatrix.containsKey(name)) {
        var m = previewMatrix[name]!;
        // simple add for preview
        base[0] = base[0] * 0.5 + m[0] * 0.5 * (intensity/50);
        base[4] = base[4] + m[4] * 0.6;
        base[6] = base[6] * 0.5 + m[6] * 0.5;
        base[9] = base[9] + m[9] * 0.6;
        base[12] = base[12] * 0.5 + m[12] * 0.5;
      }
    }
    return base;
  }

  String getFFmpeg() {
    double sharpVal = sharpen / 100 * 2.5;
    bool isPortrait = true;
    if (controller!= null) isPortrait = controller!.value.size.height > controller!.value.size.width;
    String scale = isPortrait
     ? "scale=1080:1920:force_original_aspect_ratio=decrease:flags=lanczos+accurate_rnd,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,scale=2160:3840:flags=lanczos"
      : "scale=1920:1080:force_original_aspect_ratio=decrease:flags=lanczos+accurate_rnd,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,scale=3840:2160:flags=lanczos";

    String sharp = "unsharp=5:5:" + sharpVal.toString() + ":5:5:0";
    List<String> parts = [];
    for (var f in selectedFilters) {
      if (ffmpegMap.containsKey(f)) parts.add(ffmpegMap[f]!);
    }
    String multi = parts.join(",");
    String finalF = scale + "," + sharp;
    if (multi.isNotEmpty) finalF = finalF + "," + multi;
    finalF = finalF + ",unsharp=5:5:1.0:5:5:0,eq=contrast=1.05:saturation=1.05";
    return finalF;
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() { processing = true; });
    FFmpegKitConfig.enableStatisticsCallback((s) {
      double p = 0;
      if (controller!= null) {
        var dur = controller!.value.duration.inMilliseconds;
        if (dur == 0) dur = 1;
        p = s.getTime() / dur;
      }
      if (p > 0.99) p = 0.99;
      if (p < 0) p = 0;
      setState(() { progress = p; status = (p*100).toInt().toString() + "% SAVING " + selectedFilters.join("+"); });
    });

    Directory d = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if (!await d.exists()) await d.create(recursive: true);
    String out = d.path + "/CLEAR_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";
    String vf = getFFmpeg();
    String cmd = "-y -i '" + pickedFile!.path + "' -vf \"" + vf + "\" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a copy '" + out + "'";
    var session = await FFmpegKit.execute(cmd);
    FFmpegKitConfig.enableStatisticsCallback(null);
    var rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      setState(() { processing = false; status = "DONE! Saved - " + out; progress = 1.0; });
    } else {
      setState(() { processing = false; status = "Failed"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<double> mat = getCombinedMatrix();
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(title: Text("HATKE REAL FILTER 4K", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), backgroundColor: Colors.purple, toolbarHeight: 42),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            SizedBox(height: 44, child: ElevatedButton(onPressed: processing? null : pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 44)), child: Text("SELECT VIDEO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))),
            SizedBox(height: 8),
            if (controller!= null && controller!.value.isInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!)),
                    // REAL FILTER PREVIEW - hach main fix
                    Positioned.fill(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(mat),
                        child: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!)),
                      ),
                    ),
                    Positioned(bottom: 6, left: 6, child: Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: Colors.yellow, child: Text(selectedFilters.join(" + "), style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            if (controller!= null) SizedBox(height: 6),
            if (controller!= null) LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(Colors.yellow)),
            SizedBox(height: 12),
            // Category - MOTHA KELA
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: categories.keys.map((cat) {
                bool sel = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF222222), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel? Colors.white : Colors.transparent)), child: Text(cat, style: TextStyle(color: sel? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                );
              }).toList()),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MULTI FILTER - Tap kara (Motha Button)", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: (categories[selectedCategory] as List).map((f) {
                      bool sel = selectedFilters.contains(f);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (sel) { if (selectedFilters.length > 1) selectedFilters.remove(f); } else { selectedFilters.add(f); }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8), border: sel? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.white12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (sel) Icon(Icons.check_circle, size: 14, color: Colors.black),
                            SizedBox(width: sel? 4 : 0),
                            Text(f, style: TextStyle(color: sel? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Row(children: [SizedBox(width: 70, child: Text("Sharpness", style: TextStyle(color: Colors.white70, fontSize: 11))), Expanded(child: Slider(value: sharpen, min: 0, max: 100, activeColor: Colors.pink, inactiveColor: Colors.white24, onChanged: (v) => setState(() => sharpen = v)))]),
                Row(children: [SizedBox(width: 70, child: Text("Intensity", style: TextStyle(color: Colors.white70, fontSize: 11))), Expanded(child: Slider(value: intensity, min: 0, max: 100, activeColor: Colors.yellow, inactiveColor: Colors.white24, onChanged: (v) => setState(() => intensity = v)))]),
              ]),
            ),
            SizedBox(height: 10),
            Text(status, style: TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
            SizedBox(height: 10),
            SizedBox(height: 50, child: ElevatedButton(onPressed: processing? null : convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 50)), child: Text(processing? "RENDERING..." : "EXPORT REAL CLEAR 4K - " + selectedFilters.join("+"), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
