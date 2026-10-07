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
  double progress = 0;
  Timer? timer;
  double sharp = 75;
  String selectedCategory = "Quality";
  String selectedFilter = "HD Dark";

  final categories = {
    "Quality": ["Quality Restore", "4K", "HD Light", "Focus", "Enhance", "Quality II", "HD Dark", "HD Upscale", "HD Cam 2", "HD Pet"],
    "Cinematic": ["Oppenheimer", "Wong Kar-wai", "Black Panther", "Badburry", "Freedom", "Hasselblad 2", "Green Orange", "Sicily", "Kendall", "Retro Print"],
    "Glow": ["Flash CCD", "Universal Suns", "Glow", "Cinematic Glow", "Modern Oil-paint", "Dreamy Halo"],
    "Dark": ["Dark 1", "Silver", "Humble", "Low-key"],
  };

  final ffmpegMap = {
    "BASE": "eq=brightness=0.02:contrast=1.23:saturation=1.11,unsharp=5:5:1.0:5:5:0",
    "HD Dark": "eq=brightness=0.02:contrast=1.23:saturation=1.11,colorbalance=rs=-0.12:bs=0.18,unsharp=5:5:1.0:5:5:0",
    "Quality Restore": "scale=iw*1.25:ih*1.25:flags=lanczos,scale=1080:1920:flags=lanczos,unsharp=5:5:1.6:5:5:0,eq=contrast=1.28:saturation=1.35",
    "4K": "scale=3840:2160:flags=lanczos:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2,scale=2160:3840:flags=lanczos,eq=saturation=1.30",
    "HD Light": "eq=brightness=0.14:saturation=1.30:contrast=1.12",
    "Focus": "unsharp=5:5:2.2:5:5:0,eq=contrast=1.22:saturation=1.25",
    "Enhance": "eq=contrast=1.18:brightness=0.07:saturation=1.40",
    "Quality II": "eq=contrast=1.22:saturation=1.45",
    "HD Upscale": "scale=1080:1920:flags=lanczos,scale=2160:3840:flags=lanczos,unsharp=5:5:1.2:5:5:0",
    "HD Cam 2": "eq=brightness=0.07:contrast=1.28:saturation=1.45",
    "HD Pet": "eq=saturation=1.50:contrast=1.22:brightness=0.06",
    "Oppenheimer": "eq=saturation=0.62:contrast=1.48:brightness=-0.04,curves=strong_contrast",
    "Wong Kar-wai": "curves=vintage,colorbalance=rs=0.38:gs=-0.20:bs=-0.30,eq=saturation=1.38:contrast=1.22",
    "Black Panther": "eq=saturation=0.88:contrast=1.32:brightness=-0.06,colorbalance=bs=0.22",
    "Badburry": "colorbalance=rs=0.32:bs=0.32,eq=saturation=1.45:contrast=1.32:brightness=0.08",
    "Freedom": "eq=saturation=1.65:contrast=1.28:brightness=0.09",
    "Hasselblad 2": "eq=saturation=1.38:contrast=1.28:brightness=0.05",
    "Green Orange": "colorbalance=rs=0.48:gs=-0.20:bs=-0.48,eq=saturation=1.55:contrast=1.28",
    "Sicily": "eq=saturation=0.82:contrast=1.22,colorbalance=rs=0.22:bs=-0.12,curves=vintage",
    "Kendall": "eq=saturation=1.25:contrast=1.18:brightness=0.09",
    "Retro Print": "colorbalance=gs=0.28:bs=-0.38:rs=0.28,eq=saturation=1.60:contrast=1.28:brightness=0.06",
    "Flash CCD": "eq=brightness=0.16:saturation=1.75:contrast=1.22",
    "Universal Suns": "eq=contrast=1.42:saturation=1.55:brightness=0.07,colorbalance=rs=0.42:ys=0.22,curves=vintage",
    "Glow": "gblur=sigma=0.5:steps=1,eq=brightness=0.13:saturation=1.65:contrast=1.18",
    "Cinematic Glow": "eq=brightness=0.11:saturation=1.55:contrast=1.22,gblur=sigma=0.4",
    "Modern Oil-paint": "eq=saturation=1.65:contrast=1.32",
    "Dreamy Halo": "gblur=sigma=0.9:steps=1,eq=brightness=0.11:saturation=1.45",
    "Dark 1": "eq=brightness=-0.09:contrast=1.35:saturation=0.88,curves=strong_contrast",
    "Silver": "eq=saturation=0.12:contrast=1.22:brightness=0.06",
    "Humble": "eq=saturation=0.82:contrast=1.18:brightness=-0.03",
    "Low-key": "eq=brightness=-0.14:contrast=1.50:saturation=0.78,vignette=PI/4",
  };

  // Preview sathi simple color adjust - FFmpeg sarkhach disel
  final previewMatrix = {
    "HD Dark": [1.15,0,0,0,6, 0,1.15,0,0,6, 0,0,1.28,0,12, 0,0,0,1,0],
    "Oppenheimer": [1.38,0.12,0,0,2, 0.12,0.85,0,0,-6, 0,0,0.70,0,-10, 0,0,0,1,0],
    "Wong Kar-wai": [1.42,0.15,-0.10,0,14, -0.10,1.0,-0.10,0,2, -0.20,0.12,0.78,0,-4, 0,0,0,1,0],
    "Green Orange": [1.48,0.25,0,0,14, 0.12,1.0,0,0,2, -0.35,0,0.65,0,0, 0,0,0,1,0],
    "Retro Print": [1.28,0.08,0,0,14, 0,1.14,0.05,0,8, -0.18,0.08,0.88,0,2, 0,0,0,1,0],
  };

  Future<void> pick() async {
    await Permission.storage.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r!= null) {
      timer?.cancel();
      pickedFile = File(r.files.single.path!);
      controller?.dispose();
      controller = VideoPlayerController.file(pickedFile!);
      await controller!.initialize();
      controller!.setLooping(true);
      controller!.play();
      timer = Timer.periodic(Duration(milliseconds: 800), (t) {
        if (controller!= null && controller!.value.isInitialized &&!processing && mounted) {
          var dur = controller!.value.duration.inMilliseconds;
          if (dur == 0) dur = 1;
          setState(() { progress = controller!.value.position.inMilliseconds / dur; });
        }
      });
      setState(() { status = selectedFilter + " Ready"; });
    }
  }

  String getFFmpeg() {
    double sharpVal = sharp / 100 * 2.5;
    String scale = "scale=1080:1920:force_original_aspect_ratio=decrease:flags=lanczos,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black,scale=2160:3840:flags=lanczos";
    String sharpF = "unsharp=5:5:" + sharpVal.toString() + ":5:5:0";
    String base = ffmpegMap["BASE"]!;
    String specific = ffmpegMap[selectedFilter]?? "eq=saturation=1.30:contrast=1.20";
    return scale + "," + sharpF + "," + base + "," + specific + ",unsharp=5:5:0.9:5:5:0";
  }

  Future<void> convert() async {
    if (pickedFile == null) return;
    setState(() { processing = true; progress = 0.01; });
    FFmpegKitConfig.enableStatisticsCallback((s) {
      var dur = controller!.value.duration.inMilliseconds;
      if (dur == 0) dur = 1;
      double p = s.getTime() / dur;
      if (p > 0.99) p = 0.99;
      if (mounted) setState(() { progress = p; status = (p*100).toInt().toString() + "%"; });
    });
    Directory d = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if (!await d.exists()) await d.create(recursive: true);
    String out = d.path + "/REAL_" + selectedFilter.replaceAll(" ", "_") + "_" + DateTime.now().millisecondsSinceEpoch.toString() + ".mp4";
    String vf = getFFmpeg();
    String cmd = "-y -i '" + pickedFile!.path + "' -vf \"" + vf + "\" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a copy '" + out + "'";
    var session = await FFmpegKit.execute(cmd);
    FFmpegKitConfig.enableStatisticsCallback(null);
    var rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) {
      setState(() { processing = false; progress = 1; status = "DONE! " + out; });
    } else {
      setState(() { processing = false; status = "Failed"; });
    }
  }

  @override void dispose() { timer?.cancel(); controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    var matList = previewMatrix[selectedFilter]?? [1.15,0,0,0,6, 0,1.15,0,0,6, 0,0,1.28,0,12, 0,0,0,1,0];
    List<double> mat = matList.map((e) => (e as num).toDouble()).toList();
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(title: Text("HATKE SINGLE SCREEN - FIXED", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), backgroundColor: Colors.purple, toolbarHeight: 40),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(children: [
          SizedBox(height: 50, child: ElevatedButton(onPressed: processing? null : pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 50)), child: Text("SELECT VIDEO", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)))),
          SizedBox(height: 10),
          if (controller!= null && controller!.value.isInitialized)
            Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: ColorFiltered(colorFilter: ColorFilter.matrix(mat), child: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!)))),
              SizedBox(height: 8),
              Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(6)), child: Text(selectedFilter, style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
              SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(Colors.yellow))),
            ]),
          SizedBox(height: 14),
          // FAKT EKACH CATEGORY BAR
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.keys.map((cat) { bool sel = cat == selectedCategory; return GestureDetector(onTap: () => setState(() => selectedCategory = cat), child: Container(margin: EdgeInsets.only(right: 10), padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14), decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF222222), borderRadius: BorderRadius.circular(24)), child: Text(cat, style: TextStyle(color: sel? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)))); }).toList())),
          SizedBox(height: 12),
          // FAKT EKACH FILTER BAR
          Container(width: double.infinity, padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(14)), child: Wrap(spacing: 10, runSpacing: 10, children: (categories[selectedCategory] as List).map((f) { bool sel = f == selectedFilter; return GestureDetector(onTap: () => setState(() { selectedFilter = f; status = f + " Locked"; }), child: Container(padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14), decoration: BoxDecoration(color: sel? Colors.yellow : Color(0xFF2E2E2E), borderRadius: BorderRadius.circular(12), border: sel? Border.all(color: Colors.white, width: 3) : Border.all(color: Colors.white24, width: 1)), child: Text(f, style: TextStyle(color: sel? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)))); }).toList())),
          SizedBox(height: 12),
          Text(status, style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 12),
          SizedBox(height: 56, child: ElevatedButton(onPressed: processing? null : convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 56)), child: Text(processing? "RENDERING..." : "EXPORT - " + selectedFilter, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))),
          SizedBox(height: 25),
        ]),
      ),
    );
  }
}
