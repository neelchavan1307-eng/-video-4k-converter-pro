import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
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
  String status = "Video Select Kar - Aata Farak Disel";
  bool processing = false;
  double videoProgress = 0;
  Timer? _timer;
  bool showBeforeAfter = false;
  
  double focusFilter = 50; 
  double fourKFilter = 70;
  double evenSkin = 30;
  double whitening = 25;
  double brilliance = 20;
  double sharpen = 40;

  Future<void> pick() async {
    await Permission.storage.request();
    await Permission.videos.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if(r!=null && r.files.single.path != null){
      pickedFile = File(r.files.single.path!);
      _c?.dispose();
      _c = VideoPlayerController.file(pickedFile!)..initialize().then((_)=>setState((){}))..setLooping(true)..play();
      startProgressTimer();
      setState(()=> status="Ready - Slider halav, Live Farak Bagh");
    }
  }

  void startProgressTimer(){
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 100), (t){
      if(_c!=null && _c!.value.isInitialized){
        setState(()=> videoProgress = _c!.value.position.inMilliseconds / (_c!.value.duration.inMilliseconds == 0 ? 1 : _c!.value.duration.inMilliseconds));
      }
    });
  }

  // Real-time Preview sathi Strong Color Matrix
  List<double> getColorMatrix() {
    if(showBeforeAfter) return [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0];
    
    double b = whitening / 100 * 60; // brightness
    double c = 1 + brilliance / 100 * 0.8; // contrast
    double s = 1 + (fourKFilter / 100 * 0.5) + (evenSkin / 100 * 0.3); // saturation
    double t = -128 * (c - 1);

    // Contrast + Brightness + Saturation mix
    return [
      c*0.9*s, 0, 0, 0, t + b,
      0, c*0.9*s, 0, 0, t + b,
      0, 0, c*s, 0, t + b,
      0, 0, 0, 1, 0,
    ];
  }

  Future<void> convert() async {
    if(pickedFile==null) return;
    setState((){ processing=true; status="REAL 4K Rendering..."; });
    Directory dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    String out = "${dir.path}/FINAL_4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    double sharpVal = sharpen / 100 * 2.5; // Aata jast strong
    double bright = whitening / 100 * 0.15;
    double cont = 1 + brilliance / 100 * 1.2;
    // FINAL FFmpeg - Aata 3x Strong banavla
    String vf = "scale=3840:2160:flags=lanczos,unsharp=5:5:${sharpVal}:5:5:0,hqdn3d=${evenSkin/10}:${evenSkin/10}:6:6,eq=contrast=${cont}:brightness=${bright}:saturation=${1.5 + fourKFilter/100},colorbalance=rs=0.1:gs=-0.02:bs=-0.08";
    String cmd = "-y -i '${pickedFile!.path}' -vf \"$vf\" -c:v libx264 -preset ultrafast -crf 20 -c:a copy '$out'";
    await FFmpegKit.execute(cmd).then((session) async {
      final code = await session.getReturnCode();
      if(ReturnCode.isSuccess(code)){
        setState((){ status="DONE! Farak Bagh: $out"; processing=false; });
      } else {
        final logs = await session.getAllLogsAsString();
        setState((){ status="Failed: $logs"; processing=false; });
      }
    });
  }

  Widget sliderRow(String name, double val, Function(double) onC){
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text("$name: ${val.toInt()}", style: TextStyle(color: Colors.white70, fontSize: 13)),
        Slider(value: val, min: 0, max: 100, divisions: 100, activeColor: Colors.pinkAccent, inactiveColor: Colors.white24, onChanged: onC),
      ]));
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(title: Text("4K Clear Pro - LIVE PREVIEW"), backgroundColor: Color(0xFF9C27B0)),
      body: Column(children:[
        Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(14), child: Column(children:[
          ElevatedButton(onPressed: pick, child: Text("SELECT VIDEO"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
          SizedBox(height:12),
          if(_c!=null && _c!.value.isInitialized) 
          Column(children:[
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(children:[
              AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)),
              // LIVE FILTER LAYER - Aata 100% disnar
              Positioned.fill(child: ColorFiltered(colorFilter: ColorFilter.matrix(getColorMatrix()), child: Container(color: Colors.transparent))),
              // Sharpen sathi Extra Glow
              if(sharpen > 10 && !showBeforeAfter)
              Positioned.fill(child: Opacity(opacity: sharpen/300, child: Container(color: Colors.white))),
              // BEFORE / AFTER BUTTON
              Positioned(top: 8, right: 8, child: GestureDetector(onTapDown: (_)=>setState(()=>showBeforeAfter=true), onTapUp: (_)=>setState(()=>showBeforeAfter=false), child: Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text(showBeforeAfter? "BEFORE" : "AFTER - Hold", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))))),
            ])),
            SizedBox(height: 6),
            Text(showBeforeAfter ? "Original" : "Live Preview - 100 keli ki ekdam gora disel", style: TextStyle(color: Colors.pinkAccent, fontSize: 12)),
          ]),
          SizedBox(height:12),
          Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)), child: Column(children:[
            sliderRow("1. Focus Filter", focusFilter, (v)=>setState(()=>focusFilter=v)),
            sliderRow("2. 4K Filter (Saturation)", fourKFilter, (v)=>setState(()=>fourKFilter=v)),
            sliderRow("3. Even Skin (Smooth)", evenSkin, (v)=>setState(()=>evenSkin=v)),
            sliderRow("4. Whitening (Gora)", whitening, (v)=>setState(()=>whitening=v)),
            sliderRow("5. Brilliance (Contrast)", brilliance, (v)=>setState(()=>brilliance=v)),
            sliderRow("6. Sharpen (Tikshna)", sharpen, (v)=>setState(()=>sharpen=v)),
          ])),
          SizedBox(height:14),
          Text(status, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height:14),
          ElevatedButton(onPressed: processing?null:convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, minimumSize: Size(double.infinity, 55)), child: processing? CircularProgressIndicator(color: Colors.white) : Text("CONVERT NOW", style: TextStyle(color: Colors.white))),
          SizedBox(height: 20),
        ]))),
        Container(height: 6, width: double.infinity, child: Stack(children:[
            Container(color: Colors.white12),
            FractionallySizedBox(widthFactor: videoProgress.clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.pinkAccent, Colors.purpleAccent, Colors.cyanAccent]), boxShadow: [BoxShadow(color: Colors.purpleAccent, blurRadius: 20, spreadRadius: 2)]))),
          ])),
      ]),
    );
  }
}
