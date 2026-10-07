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
  String status = "Ready";
  bool processing = false;
  double previewProgress = 0;
  double convertProgress = 0;

  double sharpen = 75;
  double fourKFilter = 85;
  double whitening = 20;
  double brilliance = 30;
  double intensity = 40;

  String selectedCategory = "Cinematic";
  List<String> selectedFilters = ["Retro Print"];

  final Map<String, List<String>> categories = {
    "Cinematic": ["Retro Print", "Badbunny", "Clear Sky", "Oppenheimer", "Wong Kar Wai", "Green Orange", "Freedom", "Hasselblad 2"],
    "Quality Enhance": ["Quality Boost", "HD Skin", "HD Uplight", "Quality II", "SACK", "Foil"],
    "Glow": ["Film CCD", "Glow", "Summer Ship", "Bright", "Dreamy Haze"],
    "Vintage": ["Antique", "Retro Film", "Classic", "Universal S.", "Bloom"],
    "Night": ["Lunar Night", "Midnight", "Urban Night", "Green Yellow"],
  };

  final Map<String, String> filterFFmpeg = {
    "Retro Print": "colorbalance=gs=0.15:bs=-0.25:rs=0.15,curves=strong_contrast,eq=saturation=1.35:contrast=1.15",
    "Badbunny": "colorbalance=rs=0.2:bs=0.2,eq=saturation=1.2:contrast=1.2:brightness=0.04",
    "Clear Sky": "eq=contrast=1.25:brightness=0.02:saturation=1.4,curves=strong_contrast,colorbalance=bs=0.15",
    "Oppenheimer": "eq=contrast=1.3:saturation=0.85:brightness=-0.02,curves=strong_contrast",
    "Wong Kar Wai": "curves=vintage,colorbalance=rs=0.2:gs=-0.1:bs=-0.2,eq=saturation=1.2",
    "Green Orange": "colorbalance=rs=0.3:gs=-0.1:bs=-0.3,eq=saturation=1.3",
    "Summer Ship": "eq=contrast=1.15:brightness=0.08:saturation=1.5:gamma=0.9,colorbalance=gs=0.2",
    "Bright": "eq=contrast=1.1:brightness=0.12:saturation=1.6",
    "Universal S.": "eq=contrast=1.3:saturation=1.35,colorbalance=rs=0.35:ys=0.2,curves=vintage",
    "Green Yellow": "colorchannelmixer=rr=1.1:gg=1.1:bb=0.9,eq=contrast=1.2:saturation=1.1",
    "Quality Boost": "unsharp=5:5:1.2:5:5:0,eq=contrast=1.2:brightness=0.03:saturation=1.4",
    "HD Skin": "eq=contrast=1.05:brightness=0.05:saturation=1.25,colorbalance=rs=0.1",
    "Film CCD": "eq=brightness=0.08:saturation=1.5,curves=strong_contrast",
    "Glow": "gblur=sigma=0.4:steps=1,eq=brightness=0.08:saturation=1.5:contrast=1.1",
    "Antique": "curves=vintage,eq=saturation=0.75,vignette=PI/4",
    "Lunar Night": "eq=contrast=1.3:brightness=-0.08:saturation=0.7,colorbalance=bs=0.25",
    "Freedom": "eq=saturation=1.3:contrast=1.15",
    "Hasselblad 2": "eq=saturation=1.25:contrast=1.2,colorbalance=rs=0.1:gs=0.05",
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
          setState(() { previewProgress = controller!.value.position.inMilliseconds / dur; });
        }
      });
      setState(() => status = "Ready - " + selectedFilters.length.toString() + " Filters");
    }
  }

  String getFFmpegFilter() {
    double sharpVal = (sharpen + 60) / 100 * 2.2;
    bool isPortrait = true;
    if (controller!= null) isPortrait = controller!.value.size.height > controller!.value.size.width;

    String scalePart = "";
    if (isPortrait) {
      scalePart = "scale=1080:1920:force_original_aspect_ratio=decrease:flags=lanczos+accurate_rnd,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black,scale=2160:3840:flags=lanczos:threads=4";
    } else {
      scalePart = "scale=1920:1080:force_original_aspect_ratio=decrease:flags=lanczos+accurate_rnd,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=black,scale=3840:2160:flags=lanczos:threads=4";
    }

    String sharp = "unsharp=5:5:" + sharpVal.toString() + ":5:5:0";
    String baseEq = "eq=brightness=" + (whitening/500).toString() + ":contrast=" + (1 + brilliance/70).toString() + ":saturation=" + (1 + fourKFilter/70).toString();

    // MULTI-FILTER LOGIC - sagale selected filters jod
    List<String> applied = [];
    for (var f in selectedFilters) {
      if (filterFFmpeg.containsKey(f)) {
        String ff = filterFFmpeg[f]!;
        // Intensity apply
        if (intensity < 50) ff = ff.replaceAll("1.35", (1 + intensity/100).toString()).replaceAll("1.3", (1 + intensity/120).toString());
        applied.add(ff);
      }
    }
    String multiPart = applied.join(",");

    String finalFilter = scalePart + "," + sharp + "," + baseEq;
    if (multiPart.isNotEmpty) finalFilter = finalFilter + "," + multiPart;
    finalFilter = finalFilter + ",unsharp=5:5:0.9:5:5:0";
    return finalFilter;
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() { processing = true; convertProgress = 0.01; });
    FFmpegKitConfig.enableStatisticsCallback((s) {
      double p = 0;
      if (controller!= null) {
        var dur = controller!.value.duration.inMilliseconds;
        if (dur == 0) dur = 1;
        p = s.getTime() / dur;
      }
      if (p > 0.99) p = 0.99;
      if (p < 0) p = 0;
      setState(() { convertProgress = p; status = (p*100).toInt().toString() + "% " + selectedFilters.join("+"); });
    });

    Directory d = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if (!await d.exists()) await d.create(recursive: true);
    String out = d.path + "/MULTI_" + selectedFilters.join("_").replaceAll(" ", "") + "_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";

    String vf = getFFmpegFilter();
    String cmd = "-y -i '" + pickedFile!.path + "' -vf \"" + vf + "\" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a copy '" + out + "'";

    var session = await FFmpegKit.execute(cmd);
    FFmpegKitConfig.enableStatisticsCallback(null);
    var rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      setState(() { processing = false; convertProgress = 1.0; status = "DONE CLEAR " + out; });
    } else {
      setState(() { processing = false; status = "Failed"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(title: Text("HATKE MULTI-FILTER 4K", style: TextStyle(fontSize: 12)), backgroundColor: Colors.purple, toolbarHeight: 36),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(6),
        child: Column(
          children: [
            SizedBox(height: 36, child: ElevatedButton(onPressed: processing? null : pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 36)), child: Text("SELECT VIDEO"))),
            if (controller!= null && controller!.value.isInitialized)
              Column(children: [
                SizedBox(height: 6),
                AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!)),
                SizedBox(height: 4),
                Container(height: 8, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(widthFactor: (processing? convertProgress : previewProgress).clamp(0.0, 1.0), alignment: Alignment.centerLeft, child: Container(color: Colors.yellow))),
                SizedBox(height: 4),
                Text(selectedFilters.join(" + "), style: TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            SizedBox(height: 6),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.keys.map((cat) { bool sel = cat == selectedCategory; return GestureDetector(onTap: () => setState(() => selectedCategory = cat), child: Container(margin: EdgeInsets.only(right: 5), padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)), child: Text(cat, style: TextStyle(color: sel? Colors.black : Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)))); }).toList())),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Multi-Select Karu Shakto - 2-3 filter ekasath", style: TextStyle(color: Colors.white38, fontSize: 8)),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 4, runSpacing: 4,
                    children: (categories[selectedCategory] as List).map((f) {
                      bool sel = selectedFilters.contains(f);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (sel) { if (selectedFilters.length > 1) selectedFilters.remove(f); }
                            else { selectedFilters.add(f); }
                            status = selectedFilters.join(" + ");
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(5), border: sel? Border.all(color: Colors.white) : null),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (sel) Icon(Icons.check, size: 10, color: Colors.black),
                            SizedBox(width: 2),
                            Text(f, style: TextStyle(color: sel? Colors.black : Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Row(children: [SizedBox(width: 45, child: Text("Sharp", style: TextStyle(color: Colors.white54, fontSize: 8))), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 1.2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3)), child: Slider(value: sharpen, min: 0, max: 100, activeColor: Colors.pink, inactiveColor: Colors.white24, onChanged: (v) => setState(() => sharpen = v))))]),
                Row(children: [SizedBox(width: 45, child: Text("4K", style: TextStyle(color: Colors.white54, fontSize: 8))), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 1.2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3)), child: Slider(value: fourKFilter, min: 0, max: 100, activeColor: Colors.pink, inactiveColor: Colors.white24, onChanged: (v) => setState(() => fourKFilter = v))))]),
                Row(children: [SizedBox(width: 45, child: Text("Intens", style: TextStyle(color: Colors.white54, fontSize: 8))), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 1.2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3)), child: Slider(value: intensity, min: 0, max: 100, activeColor: Colors.yellow, inactiveColor: Colors.white24, onChanged: (v) => setState(() => intensity = v))))]),
              ]),
            ),
            SizedBox(height: 6),
            Text(status, style: TextStyle(color: Colors.white38, fontSize: 8), textAlign: TextAlign.center),
            SizedBox(height: 6),
            SizedBox(height: 44, child: ElevatedButton(onPressed: processing? null : convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 44)), child: Text(processing? "RENDERING..." : "EXPORT " + selectedFilters.join("+") + " CLEAR 4K", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
