import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

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
  double progress = 0;
  Timer? timer;
  String selectedCategory = "Quality";
  List<String> selectedFilters = ["HD Dark"]; // MULTI
  String lastLog = "";

  final categories = {
    "Quality": ["Quality Restore", "4K", "HD Light", "Focus", "Enhance", "Quality II", "HD Dark", "HD Upscale", "HD Cam 2", "HD Pet"],
    "Cinematic": ["Oppenheimer", "Wong Kar-wai", "Black Panther", "Badburry", "Freedom", "Hasselblad 2", "Green Orange", "Sicily", "Kendall", "Retro Print"],
    "Glow": ["Flash CCD", "Universal Suns", "Glow", "Cinematic Glow", "Modern Oil-paint", "Dreamy Halo"],
    "Dark": ["Dark 1", "Silver", "Humble", "Low-key"],
  };

  final ffmpegMap = {
    "BASE": "eq=brightness=0.02:contrast=1.18:saturation=1.20",
    "HD Dark": "eq=brightness=0.02:contrast=1.23:saturation=1.11,colorbalance=rs=-0.12:bs=0.18",
    "Quality Restore": "unsharp=5:5:1.3:5:5:0,eq=contrast=1.25:saturation=1.25",
    "4K": "eq=saturation=1.25:contrast=1.18",
    "HD Light": "eq=brightness=0.12:saturation=1.25:contrast=1.10",
    "Focus": "unsharp=5:5:1.5:5:5:0,eq=contrast=1.20:saturation=1.15",
    "Enhance": "eq=contrast=1.15:saturation=1.30",
    "Quality II": "eq=contrast=1.20:saturation=1.30",
    "HD Upscale": "unsharp=5:5:1.0:5:5:0",
    "HD Cam 2": "eq=brightness=0.06:contrast=1.18:saturation=1.25",
    "HD Pet": "eq=saturation=1.35:contrast=1.12",
    "Oppenheimer": "eq=saturation=0.60:contrast=1.30:brightness=-0.04",
    "Wong Kar-wai": "colorbalance=rs=0.30:bs=-0.25,eq=saturation=1.25:contrast=1.18",
    "Black Panther": "eq=saturation=0.85:contrast=1.22,colorbalance=bs=0.12",
    "Badburry": "colorbalance=rs=0.22:bs=0.22,eq=saturation=1.30:contrast=1.20",
    "Freedom": "eq=saturation=1.40:contrast=1.18",
    "Hasselblad 2": "eq=saturation=1.25:contrast=1.18",
    "Green Orange": "colorbalance=rs=0.30:bs=-0.30,eq=saturation=1.30:contrast=1.15",
    "Sicily": "eq=saturation=0.85:contrast=1.15,colorbalance=rs=0.12",
    "Kendall": "eq=saturation=1.15:contrast=1.12",
    "Retro Print": "colorbalance=gs=0.20:bs=-0.20:rs=0.15,eq=saturation=1.35:contrast=1.18",
    "Flash CCD": "eq=brightness=0.10:saturation=1.40:contrast=1.12",
    "Universal Suns": "eq=contrast=1.22:saturation=1.30:brightness=0.04,colorbalance=rs=0.20",
    "Glow": "eq=brightness=0.08:saturation=1.35:contrast=1.10",
    "Cinematic Glow": "eq=brightness=0.06:saturation=1.30:contrast=1.15",
    "Modern Oil-paint": "eq=saturation=1.35:contrast=1.18",
    "Dreamy Halo": "eq=brightness=0.06:saturation=1.25",
    "Dark 1": "eq=brightness=-0.07:contrast=1.22:saturation=0.85",
    "Silver": "eq=saturation=0.15:contrast=1.10",
    "Humble": "eq=saturation=0.80:contrast=1.10",
    "Low-key": "eq=brightness=-0.08:contrast=1.30:saturation=0.80,vignette=angle=PI/4",
  };

  Future<void> pick() async {
    await [Permission.storage, Permission.videos, Permission.manageExternalStorage].request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r!= null) {
      timer?.cancel();
      pickedFile = File(r.files.single.path!);
      controller?.dispose();
      controller = VideoPlayerController.file(pickedFile!);
      await controller!.initialize();
      controller!.setLooping(true);
      controller!.play();
      timer = Timer.periodic(Duration(milliseconds: 600), (t) {
        if (controller!= null && controller!.value.isInitialized &&!processing && mounted) {
          var dur = controller!.value.duration.inMilliseconds;
          if (dur == 0) dur = 1;
          setState(() { progress = controller!.value.position.inMilliseconds / dur; });
        }
      });
      setState(() {});
    }
  }

  Future<String> getOutputPath() async {
    try {
      Directory d = Directory("/storage/emulated/0/Download/HATKE");
      if (!await d.exists()) await d.create(recursive: true);
      return d.path + "/HATKE_" + selectedFilters.join("_").replaceAll(" ", "") + "_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";
    } catch (_) {
      var appDir = await getExternalStorageDirectory();
      Directory d2 = Directory(appDir!.path + "/HATKE");
      if (!await d2.exists()) await d2.create(recursive: true);
      return d2.path + "/HATKE_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";
    }
  }

  String buildFilterChain() {
    String base = ffmpegMap["BASE"]!;
    List<String> parts = [base];
    for (var f in selectedFilters) {
      if (ffmpegMap.containsKey(f)) parts.add(ffmpegMap[f]!);
    }
    return parts.join(",");
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() { processing = true; progress = 0.01; status = "Rendering..."; });
    FFmpegKitConfig.enableStatisticsCallback((s) {
      var dur = controller!.value.duration.inMilliseconds;
      if (dur == 0) dur = 1;
      double p = s.getTime() / dur;
      if (p > 0.99) p = 0.99;
      if (mounted) setState(() { progress = p; status = "${(p*100).toInt()}% ${selectedFilters.join('+')}"; });
    });
    String outPath = await getOutputPath();
    String vf = "scale=1080:1920:force_original_aspect_ratio=increase:flags=lanczos,crop=1080:1920,setsar=1," + buildFilterChain();
    String cmd = "-y -i '${pickedFile!.path}' -vf \"$vf\" -c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p -c:a aac -b:a 128k '$outPath'";
    var session = await FFmpegKit.execute(cmd);
    var rc = await session.getReturnCode();
    var logs = await session.getAllLogsAsString();
    FFmpegKitConfig.enableStatisticsCallback(null);
    if (ReturnCode.isSuccess(rc)) {
      setState(() { processing = false; progress = 1; status = "SAVED: $outPath"; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to Download/HATKE")));
    } else {
      setState(() { processing = false; status = "Failed"; lastLog = logs?? ""; });
    }
  }

  @override void dispose() { timer?.cancel(); controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Color(0xFF7B1FA2), toolbarHeight: 32, title: Text("HATKE MULTI - ${selectedFilters.length} FILTERS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Expanded(
            flex: 55,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: controller!= null && controller!.value.isInitialized
             ? Stack(fit: StackFit.expand, children: [
                  FittedBox(fit: BoxFit.contain, child: SizedBox(width: controller!.value.size.width, height: controller!.value.size.height, child: VideoPlayer(controller!))),
                  Positioned(top: 8, left: 8, right: 8, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Flexible(child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(12)), child: Text(selectedFilters.join(" + "), overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)))),
                    SizedBox(width: 8),
                    GestureDetector(onTap: pick, child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Text("CHANGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                  ])),
                  Positioned(bottom: 6, left: 10, right: 10, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(Colors.yellow)))),
                ])
              : Center(child: ElevatedButton(onPressed: pick, child: Text("SELECT VIDEO"))),
            ),
          ),
          Expanded(
            flex: 45,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
              child: Column(
                children: [
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.keys.map((cat) { bool sel = cat == selectedCategory; return GestureDetector(onTap: () => setState(() => selectedCategory = cat), child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(20)), child: Text(cat, style: TextStyle(color: sel? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))); }).toList())),
                  SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("${selectedFilters.length} filters selected", style: TextStyle(color: Colors.yellow, fontSize: 11, fontWeight: FontWeight.bold)),
                    GestureDetector(onTap: () => setState(() { selectedFilters.clear(); }), child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: Text("CLEAR ALL", style: TextStyle(color: Colors.white, fontSize: 10)))),
                  ]),
                  SizedBox(height: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(spacing: 8, runSpacing: 8, children: (categories[selectedCategory] as List).map((f) { bool sel = selectedFilters.contains(f); return GestureDetector(
                        onTap: () => setState(() { if (sel) { if (selectedFilters.length > 1) selectedFilters.remove(f); } else { selectedFilters.add(f); } }),
                        child: Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF2E2E2E), borderRadius: BorderRadius.circular(10), border: sel? Border.all(color: Colors.white, width: 2) : null), child: Row(mainAxisSize: MainAxisSize.min, children: [if (sel) Icon(Icons.check, size: 14, color: Colors.black), SizedBox(width: sel? 4 : 0), Text(f, style: TextStyle(color: sel? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]))); }).toList()),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: status.contains("SAVED")? Colors.green : Colors.white70, fontSize: 10)),
                  SizedBox(height: 6),
                  SizedBox(width: double.infinity, height: 44, child: ElevatedButton(onPressed: processing? null : convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black), child: Text(processing? "RENDERING ${(progress*100).toInt()}%" : "EXPORT ${selectedFilters.length} FILTERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
