import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(MaterialApp(home: FinalApp(), debugShowCheckedModeBanner: false));

class FinalApp extends StatefulWidget { @override State<FinalApp> createState() => _FinalAppState(); }

class _FinalAppState extends State<FinalApp> {
  File? pickedFile;
  VideoPlayerController? _c;
  String status = "Video Select Kar";
  bool processing = false;
  
  // Tujhya Video Pramane - 6 Settings
  double focusFilter = 50; 
  double fourKFilter = 70;
  double evenSkin = 30; // Retouch -> Even
  double whitening = 25; // Retouch -> Whitening
  double brilliance = 20; // Adjust -> Brilliance
  double sharpen = 40; // Adjust -> Sharpen

  Future<void> pick() async {
    await Permission.storage.request();
    await Permission.videos.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if(r!=null && r.files.single.path != null){
      pickedFile = File(r.files.single.path!);
      _c?.dispose();
      _c = VideoPlayerController.file(pickedFile!)..initialize().then((_)=>setState((){}))..setLooping(true)..play();
      setState(()=> status="Ready - Saglya Settings ON");
    }
  }

  Future<void> convert() async {
    if(pickedFile==null) return;
    setState((){ processing=true; status="REAL 4K Rendering... 1-2 Min Thamb"; });
    
    Directory dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    String out = "${dir.path}/FINAL_4K_${DateTime.now().millisecondsSinceEpoch}.mp4";

    // Video madhil Formula cha REAL FFmpeg Map:
    // Focus + 4K = 3840x2160 scale + unsharp
    // Even = hqdn3d noise remove (skin smooth)
    // Whitening = brightness
    // Brilliance = contrast
    // Sharpen = unsharp
    double sharpVal = sharpen / 100 * 1.5;
    String vf = "scale=3840:2160:flags=lanczos,unsharp=5:5:${sharpVal}:5:5:0,hqdn3d=${evenSkin/10}:${evenSkin/10}:6:6,eq=contrast=${1+brilliance/100}:brightness=${0.02+whitening/400}:saturation=1.35,colorbalance=rs=0.06:bs=-0.06";

    String cmd = "-y -i '${pickedFile!.path}' -vf \"$vf\" -c:v libx264 -preset ultrafast -crf 22 -c:a copy '$out'";
    
    await FFmpegKit.execute(cmd).then((session) async {
      final code = await session.getReturnCode();
      if(ReturnCode.isSuccess(code)){
        setState((){ status="DONE! Saved: $out"; processing=false; });
      } else {
        final logs = await session.getAllLogsAsString();
        setState((){ status="Failed: $logs"; processing=false; });
      }
    });
  }

  Widget sliderRow(String name, double val, Function(double) onC){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text("$name: ${val.toInt()}", style: TextStyle(color: Colors.white70, fontSize: 13)),
        Slider(value: val, min: 0, max: 100, divisions: 100, activeColor: Colors.purpleAccent, inactiveColor: Colors.white24, onChanged: onC),
      ]),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(title: Text("4K Clear Pro - All Video Settings"), backgroundColor: Colors.purple, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: EdgeInsets.all(14), child: Column(children:[
        ElevatedButton(onPressed: pick, child: Text("SELECT VIDEO"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.white, foregroundColor: Colors.black)),
        SizedBox(height:12),
        if(_c!=null && _c!.value.isInitialized) ClipRRect(borderRadius: BorderRadius.circular(10), child: AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!))),
        SizedBox(height:12),
        Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text("Tujhya Video Pramane Settings (CapCut)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          Divider(color: Colors.white24),
          sliderRow("1. Focus Filter", focusFilter, (v)=>setState(()=>focusFilter=v)),
          sliderRow("2. 4K Filter", fourKFilter, (v)=>setState(()=>fourKFilter=v)),
          sliderRow("3. Retouch -> Even Skin", evenSkin, (v)=>setState(()=>evenSkin=v)),
          sliderRow("4. Retouch -> Whitening", whitening, (v)=>setState(()=>whitening=v)),
          sliderRow("5. Adjust -> Brilliance", brilliance, (v)=>setState(()=>brilliance=v)),
          sliderRow("6. Adjust -> Sharpen", sharpen, (v)=>setState(()=>sharpen=v)),
        ])),
        SizedBox(height:14),
        Text(status, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        SizedBox(height:14),
        ElevatedButton(onPressed: processing?null:convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, minimumSize: Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: processing? CircularProgressIndicator(color: Colors.white) : Text("CONVERT NOW - REAL 4K", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      ])),
    );
  }
}
