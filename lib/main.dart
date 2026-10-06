import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(MaterialApp(home: FinalApp(), debugShowCheckedModeBanner: false));

class FinalApp extends StatefulWidget { @override State<FinalApp> createState() => _FinalAppState(); }

class _FinalAppState extends State<FinalApp> with TickerProviderStateMixin {
  File? pickedFile;
  VideoPlayerController? _c;
  String status = "✨ Divine Mode ON Kar";
  bool processing = false;
  double progress = 0;
  late AnimationController _neonCtrl;

  double focusFilter = 50, fourKFilter = 70, evenSkin = 30, whitening = 25, brilliance = 20, sharpen = 40;
  String selectedMode = "Devi Glow";

  @override
  void initState(){ super.initState(); _neonCtrl = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat(); }

  Future<void> pick() async {
    await Permission.storage.request(); await Permission.videos.request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if(r!=null && r.files.single.path != null){
      pickedFile = File(r.files.single.path!);
      _c?.dispose();
      _c = VideoPlayerController.file(pickedFile!)..initialize().then((_)=>setState((){}))..setLooping(true)..play();
      Timer.periodic(Duration(milliseconds: 80), (t){ if(_c!=null && _c!.value.isInitialized) setState(()=> progress = _c!.value.position.inMilliseconds / (_c!.value.duration.inMilliseconds == 0 ? 1 : _c!.value.duration.inMilliseconds)); });
      setState(()=> status="Ready - Slider halav, Live farak bagh");
    }
  }

  List<double> getMatrix() {
    if(selectedMode=="Devi Glow") return [1.2,0,0,0,10+whitening/2, 0,1.15,0,0,10+whitening/2, 0,0,1.1,0,20+whitening/2, 0,0,0,1,0];
    if(selectedMode=="Cute Soft") return [1.1,0,0,0,20+whitening/2, 0,1.1,0,0,20+whitening/2, 0,0,1.2,0,25+whitening/2, 0,0,0,1,0];
    return [1.3,0,0,0,5+whitening/3, 0,1.1,0,0,5+whitening/3, 0,0,1.4,0,5+whitening/3, 0,0,0,1,0];
  }

  Future<void> convert() async {
    if(pickedFile==null) return; setState((){ processing=true; status="REAL 4K Rendering..."; });
    Directory dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    String out = "${dir.path}/HATKE_4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    double sharpVal = (sharpen + focusFilter)/100 * 1.5;
    String vf = "scale=3840:2160:flags=lanczos,unsharp=5:5:${sharpVal}:5:5:0,hqdn3d=${evenSkin/10}:${evenSkin/10}:6:6,eq=contrast=${1+brilliance/100}:brightness=${0.02+whitening/400}:saturation=${1.3+fourKFilter/100}";
    String cmd = "-y -i '${pickedFile!.path}' -vf \"$vf\" -c:v libx264 -preset ultrafast -crf 20 -c:a copy '$out'";
    await FFmpegKit.execute(cmd).then((s) async { if(ReturnCode.isSuccess(await s.getReturnCode())) setState((){ status="DONE! $out"; processing=false; }); else setState((){ status="Failed"; processing=false; }); });
  }

  Widget modeChip(String name, IconData icon, Color col){
    bool sel = selectedMode==name;
    return GestureDetector(onTap: ()=>setState(()=>selectedMode=name), child: AnimatedContainer(duration: Duration(milliseconds: 300), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: sel? col : Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel? Colors.white : col.withOpacity(0.4)), boxShadow: sel? [BoxShadow(color: col, blurRadius: 12)]:[]), child: Row(mainAxisSize: MainAxisSize.min, children:[Icon(icon, size: 12, color: Colors.white), SizedBox(width: 4), Text(name, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]))); 
  }

  Widget miniSlider(String name, double val, Function(double) onC){
    return Padding(padding: EdgeInsets.only(bottom: 2), child: Row(children:[SizedBox(width: 95, child: Text(name, style: TextStyle(color: Colors.white60, fontSize: 11))), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 2, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: RoundSliderOverlayShape(overlayRadius: 10)), child: Slider(value: val, min: 0, max: 100, activeColor: Colors.pinkAccent, inactiveColor: Colors.white24, onChanged: onC))), SizedBox(width: 28, child: Text("${val.toInt()}", style: TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.bold)))]));
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(backgroundColor: Color(0xFF0A0A0A), appBar: AppBar(title: Text("HATKE 4K • 6 Functions", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple, Colors.pinkAccent]))))),
      body: SingleChildScrollView(padding: EdgeInsets.all(10), child: Column(children:[
        ElevatedButton(onPressed: pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity, 42), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text("SELECT VIDEO", style: TextStyle(fontSize: 13))),
        SizedBox(height: 8),
        if(_c!=null && _c!.value.isInitialized) Column(children:[
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(children:[AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)), Positioned.fill(child: ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: Container())), Positioned.fill(child: CustomPaint(painter: SparklePainter()))])),
          SizedBox(height: 8),
          Container(height: 10, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white10), child: Stack(children:[
            FractionallySizedBox(widthFactor: progress.clamp(0.0, 1.0), child: AnimatedBuilder(animation: _neonCtrl, builder: (_,__)=> Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Colors.pinkAccent, Colors.cyanAccent, Colors.yellowAccent, Colors.pinkAccent], transform: GradientRotation(_neonCtrl.value*6.28)), boxShadow: [BoxShadow(color: Colors.pinkAccent, blurRadius: 12)])))),
          ])),
          SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Text("● REAL TIME PREVIEW", style: TextStyle(color: Colors.pinkAccent, fontSize: 9, fontWeight: FontWeight.bold)), Text("${(progress*100).toInt()}%", style: TextStyle(color: Colors.cyanAccent, fontSize: 9))]),
        ]),
        SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children:[modeChip("Devi Glow", Icons.auto_awesome, Colors.orange), SizedBox(width: 6), modeChip("Cute Soft", Icons.favorite, Colors.pink), SizedBox(width: 6), modeChip("Cyber Pop", Icons.bolt, Colors.cyan)])),
        SizedBox(height: 8),
        Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)), child: Column(children:[
          miniSlider("1. Focus Filter", focusFilter, (v)=>setState(()=>focusFilter=v)),
          miniSlider("2. 4K Filter", fourKFilter, (v)=>setState(()=>fourKFilter=v)),
          miniSlider("3. Even Skin", evenSkin, (v)=>setState(()=>evenSkin=v)),
          miniSlider("4. Whitening", whitening, (v)=>setState(()=>whitening=v)),
          miniSlider("5. Brilliance", brilliance, (v)=>setState(()=>brilliance=v)),
          miniSlider("6. Sharpen", sharpen, (v)=>setState(()=>sharpen=v)),
        ])),
        SizedBox(height: 10),
        Text(status, style: TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
        SizedBox(height: 10),
        ElevatedButton(onPressed: processing?null:convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: processing? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text("EXPORT REAL 4K", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        SizedBox(height: 25),
      ])),
    );
  }
}

class SparklePainter extends CustomPainter{
  @override void paint(Canvas c, Size s){ var r = Random(); var p = Paint()..color = Colors.white.withOpacity(0.6); for(int i=0;i<8;i++){ c.drawCircle(Offset(r.nextDouble()*s.width, r.nextDouble()*s.height), r.nextDouble()*1.2, p..maskFilter = MaskFilter.blur(BlurStyle.normal, 2)); } }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
