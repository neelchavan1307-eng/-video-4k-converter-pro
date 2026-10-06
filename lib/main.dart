import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
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
  
  // Tujhya Video Pramane Settings
  double focusFilter = 50; // Focus filter
  double fourKFilter = 70; // 4K filter
  double evenSkin = 30; // Retouch -> Even
  double whitening = 25; // Retouch -> Whitening
  double brilliance = 20; // Adjust -> Brilliance
  double sharpen = 40; // Adjust -> Sharpen

  Future<void> pick() async {
    await Permission.storage.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if(r!=null){
      pickedFile = File(r.files.single.path!);
      _c = VideoPlayerController.file(pickedFile!)..initialize().then((_)=>setState((){}))..setLooping(true)..play();
      setState(()=> status="Ready");
    }
  }

  Future<void> convert() async {
    if(pickedFile==null) return;
    setState((){ processing=true; status="REAL 4K Cinematic Rendering... 1 Min Thamb"; });
    Directory dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    String out = "${dir.path}/FINAL_4K_${DateTime.now().millisecondsSinceEpoch}.mp4";

    // Tujhya Video cha Formula FFmpeg madhe:
    // Even = hqdn3d (skin smooth), Whitening = brightness, Brilliance = contrast+brightness, Sharpen = unsharp
    // Focus + 4K = scale 4K + unsharp + saturation
    String vf = "scale=3840:2160:flags=lanczos,unsharp=5:5:${sharpen/50}:5:5:0,hqdn3d=${evenSkin/10}:${evenSkin/10}:6:6,eq=contrast=${1+brilliance/100}:brightness=${0.02+whitening/500}:saturation=1.3,colorbalance=rs=0.05:bs=-0.05";

    String cmd = "-y -i '${pickedFile!.path}' -vf \"$vf\" -c:v libx264 -preset ultrafast -crf 22 -c:a copy '$out'";
    
    await FFmpegKit.execute(cmd).then((s) async {
      final c = await s.getReturnCode();
      if(c!=null && c.isValueSuccess()){
        setState((){ status="DONE! Gallery madhe bagh: $out"; processing=false; });
      } else {
        setState((){ status="Failed"; processing=false; });
      }
    });
  }

  Widget sliderRow(String name, double val, Function(double) onC){
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text("$name: ${val.toInt()}", style: TextStyle(color: Colors.white70, fontSize: 13)),
      Slider(value: val, min: 0, max: 100, activeColor: Colors.purpleAccent, onChanged: onC),
    ]);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("4K Convert - All Settings"), backgroundColor: Colors.purple),
      body: SingleChildScrollView(padding: EdgeInsets.all(14), child: Column(children:[
        ElevatedButton(onPressed: pick, child: Text("SELECT VIDEOS"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
        SizedBox(height:10),
        if(_c!=null && _c!.value.isInitialized) AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)),
        SizedBox(height:10),
        Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Column(children:[
          Text("Tujhya Video Pramane Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          sliderRow("1. Focus Filter (Video madhil dusra filter)", focusFilter, (v)=>setState(()=>focusFilter=v)),
          sliderRow("2. 4K Filter (Search karun lavlela)", fourKFilter, (v)=>setState(()=>fourKFilter=v)),
          sliderRow("3. Retouch -> Even Skin", evenSkin, (v)=>setState(()=>evenSkin=v)),
          sliderRow("4. Retouch -> Whitening", whitening, (v)=>setState(()=>whitening=v)),
          sliderRow("5. Adjust -> Brilliance", brilliance, (v)=>setState(()=>brilliance=v)),
          sliderRow("6. Adjust -> Sharpen / Clarity", sharpen, (v)=>setState(()=>sharpen=v)),
        ])),
        SizedBox(height:12),
        Text(status, style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        SizedBox(height:12),
        ElevatedButton(onPressed: processing?null:convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, minimumSize: Size(double.infinity, 55)), child: processing? CircularProgressIndicator(color: Colors.white) : Text("CONVERT NOW - REAL 4K", style: TextStyle(color: Colors.white, fontSize: 16))),
      ])),
    );
  }
}
