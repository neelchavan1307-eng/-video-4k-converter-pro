import 'dart:io';
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
  double progress = 0;
  String selectedCategory = "Quality";
  List<String> selectedFilters = ["HD Dark"];

  final categories = {
    "Quality": ["Quality Restore", "4K", "HD Light", "Focus", "Enhance", "Quality II", "HD Dark", "HD Upscale", "HD Cam 2", "HD Pet"],
    "Cinematic": ["Oppenheimer", "Wong Kar-wai", "Black Panther", "Badburry", "Freedom", "Hasselblad 2", "Green Orange", "Sicily", "Kendall", "Retro Print"],
    "Glow": ["Flash CCD", "Universal Suns", "Glow", "Cinematic Glow", "Modern Oil-paint", "Dreamy Halo"],
    "Dark": ["Dark 1", "Silver", "Humble", "Low-key"],
  };

  final ffmpegMap = {
    "BASE": "eq=brightness=0.02:contrast=1.18:saturation=1.20",
    "HD Dark": "eq=brightness=0.02:contrast=1.23:saturation=1.11,colorbalance=rs=-0.12:bs=0.18",
    "Quality Restore": "unsharp=5:5:1.3:5:5:0,eq=contrast=1.25:saturation=1.30",
    "4K": "eq=saturation=1.30:contrast=1.18,unsharp=5:5:0.8:5:5:0",
    "HD Light": "eq=brightness=0.12:saturation=1.30:contrast=1.10",
    "Focus": "unsharp=5:5:1.8:5:5:0,eq=contrast=1.20",
    "Enhance": "eq=contrast=1.18:saturation=1.35:brightness=0.04",
    "Quality II": "eq=contrast=1.20:saturation=1.35:brightness=0.04",
    "HD Upscale": "unsharp=5:5:1.0:5:5:0,eq=saturation=1.25",
    "HD Cam 2": "eq=brightness=0.06:contrast=1.20:saturation=1.30",
    "HD Pet": "eq=saturation=1.45:contrast=1.15:brightness=0.04",
    "Oppenheimer": "eq=saturation=0.55:contrast=1.40:brightness=-0.05,curves=strong_contrast",
    "Wong Kar-wai": "curves=vintage,colorbalance=rs=0.32:gs=-0.15:bs=-0.25,eq=saturation=1.35:contrast=1.22",
    "Black Panther": "eq=saturation=0.80:contrast=1.30:brightness=-0.05,colorbalance=bs=0.18",
    "Badburry": "colorbalance=rs=0.28:bs=0.28,eq=saturation=1.45:contrast=1.30:brightness=0.06",
    "Freedom": "eq=saturation=1.65:contrast=1.25:brightness=0.06",
    "Hasselblad 2": "eq=saturation=1.40:contrast=1.25:brightness=0.04",
    "Green Orange": "colorbalance=rs=0.40:gs=-0.15:bs=-0.40,eq=saturation=1.50:contrast=1.25",    "Sicily": "eq=saturation=0.80:contrast=1.20,colorbalance=rs=0.18:bs=-0.10",
    "Kendall": "eq=saturation=1.25:contrast=1.15:brightness=0.05",
    "Retro Print": "colorbalance=gs=0.25:bs=-0.30:rs=0.20,eq=saturation=1.55:contrast=1.25:brightness=0.05",
    "Flash CCD": "eq=brightness=0.14:saturation=1.70:contrast=1.18,unsharp=5:5:1.0:5:5:0",
    "Universal Suns": "eq=contrast=1.35:saturation=1.45:brightness=0.06,colorbalance=rs=0.30:ys=0.15,curves=vintage",
    "Glow": "eq=brightness=0.10:saturation=1.50:contrast=1.12",
    "Cinematic Glow": "eq=brightness=0.08:saturation=1.45:contrast=1.20",
    "Modern Oil-paint": "eq=saturation=1.60:contrast=1.28",
    "Dreamy Halo": "eq=brightness=0.08:saturation=1.35:contrast=1.10",
    "Dark 1": "eq=brightness=-0.08:contrast=1.30:saturation=0.80,curves=strong_contrast",
    "Silver": "eq=saturation=0.10:contrast=1.18:brightness=0.04",
    "Humble": "eq=saturation=0.78:contrast=1.15:brightness=-0.02",
    "Low-key": "eq=brightness=-0.12:contrast=1.45:saturation=0.75,vignette=angle=PI/4",
  };

  final previewMatrix = {
    "HD Dark": [1.18,0.0,0.0,0.0,8.0, 0.0,1.18,0.0,0.0,8.0, 0.0,0.0,1.30,0.0,14.0, 0.0,0.0,0.0,1.0,0.0],
    "Retro Print": [1.30,0.10,0.0,0.0,12.0, 0.0,1.10,0.05,0.0,6.0, -0.15,0.05,0.85,0.0,0.0, 0.0,0.0,0.0,1.0,0.0],
    "Oppenheimer": [1.40,0.10,0.0,0.0,0.0, 0.10,0.85,0.0,0.0,-5.0, 0.0,0.0,0.70,0.0,-8.0, 0.0,0.0,0.0,1.0,0.0],
    "Universal Suns": [1.35,0.15,0.0,0.0,8.0, 0.08,1.10,0.0,0.0,0.0, 0.0,0.0,0.75,0.0,-2.0, 0.0,0.0,0.0,1.0,0.0],
  };

  List<double> getCombinedMatrix() {
    List<double> base = [1.0,0.0,0.0,0.0,0.0, 0.0,1.0,0.0,0.0,0.0, 0.0,0.0,1.0,0.0,0.0, 0.0,0.0,0.0,1.0,0.0];
    if (selectedFilters.isEmpty) return base;
    List<double> first = (previewMatrix[selectedFilters.first]?? base).map((e) => (e as num).toDouble()).toList();
    return first;
  }

  Future<void> pick() async {
    await [Permission.storage, Permission.videos, Permission.manageExternalStorage].request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r!= null) {
      pickedFile = File(r.files.single.path!);
      await controller?.dispose();
      controller = VideoPlayerController.file(pickedFile!);
      await controller!.initialize();
      controller!.setLooping(true);
      controller!.play();
      setState(() {});
    }
  }

  Future<String> getOutputPath() async {
    try {
      Directory d = Directory("/storage/emulated/0/DCIM/HATKE");
      if (!await d.exists()) await d.create(recursive: true);
      return d.path + "/HATKE_${DateTime.now().millisecondsSinceEpoch}.mp4";
    } catch (_) {
      Directory d = Directory("/storage/emulated/0/Movies/HATKE");
      if (!await d.exists()) await d.create(recursive: true);
      return d.path + "/HATKE_${DateTime.now().millisecondsSinceEpoch}.mp4";
    }
  }

  String buildChain() {
    List<String> parts = [ffmpegMap["BASE"]!];
    for (var f in selectedFilters) {
      if (ffmpegMap.containsKey(f)) parts.add(ffmpegMap[f]!);
    }
    return parts.join(",");
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() { processing = true; progress = 0.01; status = "Rendering..."; });
    FFmpegKitConfig.enableStatisticsCallback((s) {
      if (controller == null) return;
      var dur = controller!.value.duration.inMilliseconds;
      if (dur == 0) dur = 1;
      double p = s.getTime() / dur;
      if (p > 0.99) p = 0.99;
      if (mounted) setState(() { progress = p; status = "${(p*100).toInt()}%"; });
    });
    String outPath = await getOutputPath();
    String vf = "scale=1080:1920:force_original_aspect_ratio=increase:flags=lanczos,crop=1080:1920,setsar=1,${buildChain()}";
    String cmd = "-y -i '${pickedFile!.path}' -vf \"$vf\" -c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p -c:a aac -b:a 128k '$outPath'";
    var session = await FFmpegKit.execute(cmd);
    FFmpegKitConfig.enableStatisticsCallback(null);
    var rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      try { await Process.run('am', ['broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file://$outPath']); } catch(_){}
      setState(() { processing = false; progress = 1; status = "SAVED to Gallery"; });
    } else {
      setState(() { processing = false; status = "Failed"; });
    }
  }

  @override void dispose() { controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    List<double> mat = getCombinedMatrix();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Color(0xFF7B1FA2), toolbarHeight: 34, title: Text("HATKE - ${selectedFilters.length} FILTERS LIVE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), actions: [TextButton(onPressed: pick, child: Text("CHANGE", style: TextStyle(color: Colors.white, fontSize: 12)))]),
      body: Column(
        children: [
          Container(height: MediaQuery.of(context).size.height * 0.55, width: double.infinity, color: Colors.black, child: controller!= null && controller!.value.isInitialized? Stack(children: [Center(child: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: ColorFiltered(colorFilter: ColorFilter.matrix(mat), child: VideoPlayer(controller!)))), Positioned(top: 8, left: 8, child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(12)), child: Text(selectedFilters.join(" + "), style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)))), if (processing) Positioned(bottom: 8, left: 10, right: 10, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(Colors.yellow))))]): Center(child: ElevatedButton(onPressed: pick, child: Text("SELECT VIDEO")))),
          Expanded(child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(16))), child: Column(children: [SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.keys.map((cat) { bool sel = cat == selectedCategory; return GestureDetector(onTap: () => setState(() => selectedCategory = cat), child: Container(margin: EdgeInsets.only(right: 8), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(20)), child: Text(cat, style: TextStyle(color: sel? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))); }).toList())), SizedBox(height: 8), Expanded(child: SingleChildScrollView(child: Wrap(spacing: 8, runSpacing: 8, children: (categories[selectedCategory] as List).map((f) { bool sel = selectedFilters.contains(f); return GestureDetector(onTap: () => setState(() { if (sel) { if (selectedFilters.length > 1) selectedFilters.remove(f); } else { selectedFilters.add(f); } }), child: Container(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF2E2E2E), borderRadius: BorderRadius.circular(10), border: sel? Border.all(color: Colors.white, width: 2): null), child: Text(f, style: TextStyle(color: sel? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))); }).toList()))), SizedBox(height: 6), SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: processing? null : convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black), child: Text(processing? "RENDERING ${(progress*100).toInt()}%" : "EXPORT - ${selectedFilters.join('+')} - $status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))))]))),
        ],
      ),
    );
  }
}
