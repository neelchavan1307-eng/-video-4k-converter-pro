import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MaterialApp(home: HatkeApp(), debugShowCheckedModeBanner: false));

class HatkeApp extends StatefulWidget { @override State<HatkeApp> createState() => _HatkeAppState(); }

class _HatkeAppState extends State<HatkeApp> {
  VideoPlayerController? _controller;
  List<String> selected = ["HD Dark"];
  bool isExporting = false;
  double progress = 0;
  String videoPath = ""; // तुझा original video path इथे येईल

  // तुझ्या व्हिडिओ चे filters - इथेच खरी जादू आहे
  Map<String, String> ffmpegFilters = {
    "HD Dark": "eq=brightness=-0.15:contrast=1.3:saturation=0.8",
    "Quality Restore": "unsharp=5:5:1.0",
    "4K": "scale=1920:1080:flags=lanczos,unsharp=5:5:1.0",
    "HD Light": "eq=brightness=0.1:contrast=1.1",
    "Oppenheimer": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131:0",
    "Wong-kar-wai": "colorbalance=rs=0.3:gs=-0.1:bs=-0.2",
    "Black Panther": "eq=contrast=1.4:saturation=1.3",
    "Badburry": "sepia=0.3",
    "Freedom": "eq=saturation=1.5",
    "Hasselblad 2": "curves=vintage",
    "Green Orange": "colorbalance=rs=0.2:gs=0.1:bs=-0.2:rm=0.1:gm=0.05:bm=-0.1",
    "Sicily": "colorchannelmixer=1.2:0:0:0:0:1.1:0:0:0:0:0.9:0",
    "Kendall": "eq=brightness=0.05:contrast=1.2:saturation=1.2:gamma=0.9",
    "Retro Print": "curves=strong_contrast",
    "Glow": "gblur=sigma=0.5:steps=1,eq=brightness=0.1:saturation=1.3",
    "Universal Suns": "colorbalance=rs=0.4:gs=0.2:bs=-0.1,eq=brightness=0.08",
    "Cinematic Glow": "glow=0.5:0.8:0.5:0.8:0.8,eq=contrast=1.15",
    "Flash CCD": "eq=contrast=1.2:brightness=0.05",
  };

  // Live Preview साठी Color Filter
  Map<String, ColorFilter> previewFilters = {
    "HD Dark": ColorFilter.matrix([0.9,0,0,0,0, 0,0.9,0,0,0, 0,0,0.8,0,0, 0,0,0,1,0]),
    "Oppenheimer": ColorFilter.matrix([1.2,0.2,0,0,0, 0.1,1.1,0,0,0, 0,0,0.8,0,0, 0,0,0,1,0]),
    "Kendall": ColorFilter.matrix([1.1,0,0,0,10, 0,1.05,0,0,5, 0,0,1.0,0,0, 0,0,0,1,0]),
    "Green Orange": ColorFilter.matrix([1.2,0,0,0,0, 0,1.1,0,0,0, 0,0,0.9,0,0, 0,0,0,1,0]),
    "Glow": ColorFilter.matrix([1.2,0,0,0,15, 0,1.2,0,0,15, 0,0,1.2,0,0, 0,0,0,1,0]),
  };

  @override
  void initState(){
    super.initState();
    // इथे तुझा gallery मधून video pick चा code असेल
    // _controller = VideoPlayerController.file(File(videoPath))..initialize().then((_)=>setState((){})..play()..setLooping(true));
  }

  String buildFfmpegCommand(){
    List<String> filters = [];
    for(var f in selected){
      if(ffmpegFilters.containsKey(f)) filters.add(ffmpegFilters[f]!);
    }
    if(filters.isEmpty) return "";
    return filters.join(",");
  }

  Future<void> exportVideo() async {
    if(videoPath.isEmpty){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("आधी व्हिडिओ सिलेक्ट कर"))); return; }
    setState(()=> isExporting = true);
    await Permission.storage.request(); await Permission.videos.request();

    Directory temp = await getTemporaryDirectory();
    String outPath = "${temp.path}/HATKE_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String vf = buildFfmpegCommand();
    String cmd = "-i $videoPath -vf \"$vf\" -c:a copy -preset ultrafast $outPath";

    print("FFMPEG CMD: $cmd");
    await FFmpegKit.execute(cmd).then((session) async {
      final code = await session.getReturnCode();
      if(ReturnCode.isSuccess(code)){
        // Gallery मध्ये Save
        Directory dcim = Directory("/storage/emulated/0/DCIM/HATKE");
        if(!await dcim.exists()) await dcim.create(recursive: true);
        String finalPath = "${dcim.path}/HATKE_${DateTime.now().millisecondsSinceEpoch}.mp4";
        await File(outPath).copy(finalPath);
        await GallerySaver.saveVideo(finalPath);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save झालं - Gallery मध्ये बघ: DCIM/HATKE")));
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export Fail - Log बघ")));
      }
      setState(()=> isExporting = false);
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.purple, title: Text("HATKE - ${selected.length} FILTERS LIVE", style: TextStyle(fontSize: 12)), actions: [TextButton(onPressed: (){ setState(()=> selected.clear()); }, child: Text("CLEAR", style: TextStyle(color: Colors.white)))]),
      body: Column(children: [
        // Top filter name strip - तुझ्या व्हिडिओ सारखा
        Container(color: Colors.yellow, width: double.infinity, padding: EdgeInsets.all(4), child: Text(selected.join(" + "), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        // Video Preview with LIVE filter
        Expanded(child: _controller!=null && _controller!.value.isInitialized?
          ColorFiltered(
            colorFilter: previewFilters[selected.isNotEmpty? selected.last : "HD Dark"]?? ColorFilter.mode(Colors.transparent, BlendMode.multiply),
            child: VideoPlayer(_controller!)
          ) : Center(child: Text("व्हिडिओ लोड होतोय...", style: TextStyle(color: Colors.white)))
        ),
        // Filter Buttons - तुझ्या व्हिडिओ सारखेच
        Container(height: 220, color: Color(0xFF1A1A1A), child: SingleChildScrollView(child: Column(children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for(var cat in ["Quality","Cinematic","Glow","Dark"])
              ChoiceChip(label: Text(cat, style: TextStyle(fontSize: 11)), selected: false, onSelected: (_){}),
          ]),
          SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for(var f in ffmpegFilters.keys)
              FilterChip(
                label: Text(f, style: TextStyle(fontSize: 10)),
                selected: selected.contains(f),
                selectedColor: Colors.yellow,
                onSelected: (v){ setState(()=> v? selected.add(f) : selected.remove(f)); },
              )
          ]),
        ]))),
        // EXPORT Button - हाच Fix केलाय
        Container(width: double.infinity, padding: EdgeInsets.all(10), child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
          onPressed: isExporting? null : exportVideo,
          child: isExporting? Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(width: 10), Text("Exporting ${progress.toInt()}%")]) : Text("EXPORT - ${selected.join("+")} - Ready", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
        ))
      ]),
    );
  }
}
