import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() { runApp(MaterialApp(home: MergedApp(), debugShowCheckedModeBanner: false)); }

class MergedApp extends StatefulWidget { @override State<MergedApp> createState() => _MergedAppState(); }

class _MergedAppState extends State<MergedApp> {
  File? pickedFile;
  VideoPlayerController? _c;
  String status = "Video Select Kara";
  bool processing = false;
  bool showComparison = true;
  double previewProgress = 0, convertProgress = 0;

  double focusFilter = 50, fourKFilter = 70, evenSkin = 30, whitening = 25, brilliance = 20, sharpen = 60;
  String selectedMode = "Devi Glow";
  double intensity = 40;
  String selectedCategory = "Cinematic";
  String selectedFilter = "Oppenheimer";

  Map<String, List<String>> categories = {
    "Cinematic": ["Green Orange", "Sicily", "Badbunny", "Wong Kar Wai", "Hasselblad 2", "Oppenheimer", "Freedom", "Kendall", "Black Panther"],
    "Quality Enhance": ["Quality Boost", "SACK", "HS Logger", "Foil", "Praise", "Quality II", "HD Skin", "HD Uplight"],
    "Glow": ["Film CCD", "Hawaii Sunset", "Glow", "Mystic Glow", "Modern Sunrise", "Dreamy Haze"],
    "Vintage": ["Antique", "Retro Film", "Film", "Classic", "Olden", "Hazy", "Bloom", "Brownie"],
    "Night": ["Lunar Night", "Dark Film", "Midnight", "Starry Night", "Moody Film", "Urban Night"],
  };

  Future<void> pick() async {
    await [Permission.storage, Permission.videos, Permission.manageExternalStorage].request();
    var r = await FilePicker.platform.pickFiles(type: FileType.video);
    if(r!=null){
      pickedFile = File(r.files.single.path!);
      _c?.dispose();
      _c = VideoPlayerController.file(pickedFile!)..initialize().then((_)=>setState((){}))..setLooping(true)..play();
      Timer.periodic(Duration(milliseconds: 200), (t){ if(_c!=null && _c!.value.isInitialized) setState(()=> previewProgress = _c!.value.position.inMilliseconds / (_c!.value.duration.inMilliseconds==0?1:_c!.value.duration.inMilliseconds)); });
      setState(()=> status="Ready");
    }
  }

  List<double> getMatrix(){
    double w = whitening; double i = intensity/50;
    List<double> base;
    if(selectedMode=="Devi Glow") base=[1.4,0,0,0,15+w, 0,1.2,0,0,10+w, 0,0,0.9,0,-5+w, 0,0,0,1,0];
    else if(selectedMode=="Cute Soft") base=[1.3,0.1,0.1,0,25+w, 0.1,1.2,0.1,0,20+w, 0.1,0.1,1.4,0,30+w, 0,0,0,1,0];
    else base=[1.6,-0.1,0,0,5+w/2, -0.1,1.1,0,0,5+w/2, 0,0,1.8,0,5+w/2, 0,0,0,1,0];
    if(selectedFilter=="Oppenheimer") base[0]+=0.1*i;
    if(selectedFilter=="Glow") { base[4]+=20*i; base[9]+=15*i; base[14]+=20*i; }
    if(selectedFilter=="Lunar Night") base[2]+=0.2*i;
    return base;
  }

  Future<void> convert() async {
    if(pickedFile==null) return;
    setState((){ processing=true; convertProgress=0.01; });
    FFmpegKitConfig.enableStatisticsCallback((s){ double p = s.getTime() / _c!.value.duration.inMilliseconds; if(p>0.99) p=0.99; if(p<0) p=0; setState((){ convertProgress=p; status="${(p*100).toInt()}% ${selectedFilter} REAL 4K..."; }); });

    Directory d = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if(!await d.exists()) await d.create(recursive:true);
    String out = "${d.path}/HATKE_CLEAR_${selectedFilter}_${DateTime.now().millisecondsSinceEpoch}.mp4";

    double sharpVal = (sharpen + focusFilter)/100 * 2.5;
    bool isPortrait = _c!.value.size.height > _c!.value.size.width;
    String scalePart = isPortrait? "scale=1080:1920:flags=lanczos+accurate_rnd+full_chroma_int:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black,scale=2160:3840:flags=lanczos"
                                 : "scale=1920:1080:flags=lanczos+accurate_rnd+full_chroma_int:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=black,scale=3840:2160:flags=lanczos";

    double ii = intensity/100;
    String oldVf = "unsharp=5:5:${sharpVal}:5:5:0,eq=contrast=${1+brilliance/80}:brightness=${0.03+whitening/300}:saturation=${1.4+fourKFilter/80}";

    String newVf;
    if(selectedFilter=="Oppenheimer") newVf="eq=contrast=${1.3+ii}:brightness=-0.02:saturation=0.85:gamma=1.15, curves=strong_contrast";
    else if(selectedFilter=="Quality Boost") newVf="unsharp=5:5:1.2:5:5:0,eq=contrast=${1.2+ii}:brightness=0.03:saturation=1.4";
    else if(selectedFilter=="Glow") newVf="eq=brightness=${0.08+ii}:saturation=1.5, gblur=sigma=0.4:steps=1, eq=contrast=1.1";
    else if(selectedFilter=="Antique") newVf="curves=vintage,eq=saturation=0.75, vignette=PI/4";
    else if(selectedFilter=="Lunar Night") newVf="eq=contrast=1.3:brightness=-0.08:saturation=0.7, colorbalance=bs=0.25:gm=0.1";
    else newVf="eq=contrast=${1.15+ii}:saturation=${1.2+ii}:brightness=${ii*0.05}";

    String finalVf = "$scalePart,$oldVf,$newVf,unsharp=5:5:0.8:5:5:0";
    String cmd = "-y -i '${pickedFile!.path}' -vf \"$finalVf\" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k '$out'";

    await FFmpegKit.execute(cmd).then((s) async {
      FFmpegKitConfig.enableStatisticsCallback(null);
      if(ReturnCode.isSuccess(await s.getReturnCode())){ setState((){ convertProgress=1.0; processing=false; status="DONE! Ekdam Clear Saved!\n$out"; }); }
      else { setState((){ processing=false; status="Failed"; }); }
    });
  }

  Widget modeChip(String n, IconData ic, Color c){ bool sel=selectedMode==n; return GestureDetector(onTap: ()=>setState(()=>selectedMode=n), child: Container(padding: EdgeInsets.symmetric(horizontal:10,vertical:5), decoration: BoxDecoration(color: sel?c:Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(15), border: Border.all(color: sel?Colors.white:c.withOpacity(0.6),width:0.8)), child: Row(mainAxisSize:MainAxisSize.min,children:[Icon(ic,size:10,color:Colors.white),SizedBox(width:3),Text(n,style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.bold))]))) ;}

  Widget miniSlider(String n, double v, Function(double) onC){
    return Padding(padding: EdgeInsets.only(bottom:2), child: Row(children:[
      SizedBox(width:75,child: Text(n,style:TextStyle(color:Colors.white.withOpacity(0.6),fontSize:8))),
      Expanded(child: SliderTheme(data: SliderThemeData(trackHeight:1.5, thumbShape: RoundSliderThumbShape(enabledThumbRadius:4), overlayShape: RoundSliderOverlayShape(overlayRadius:8)), child: Slider(value:v,min:0,max:100,activeColor:Colors.pinkAccent,inactiveColor:Colors.white.withOpacity(0.2), onChanged:(vv)=>setState(()=>onC(vv))))),
      SizedBox(width:22,child: Text("${v.toInt()}",style:TextStyle(color:Colors.pinkAccent,fontSize:8,fontWeight:FontWeight.bold)))
    ]));
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(backgroundColor: Color(0xFF0A0A0A), appBar: AppBar(title: Text("HATKE 4K - REAL CLEAR",style:TextStyle(fontSize:14)), backgroundColor: Colors.purple, toolbarHeight:40),
      body: SingleChildScrollView(padding: EdgeInsets.all(8), child: Column(children:[
        SizedBox(height:42, child: ElevatedButton(onPressed: processing?null:pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity,36), padding:EdgeInsets.zero), child: Text("SELECT VIDEO",style:TextStyle(fontSize:12)))),
        if(_c!=null && _c!.value.isInitialized)...[
          SizedBox(height:6),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Stack(children:[
            AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)),
            if(!showComparison) Positioned.fill(child: ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: Container())),
            if(showComparison) Positioned.fill(child: Row(children:[
              Expanded(child: Stack(children:[AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)), Positioned(bottom:3,left:3,child: Container(color:Colors.black54,padding:EdgeInsets.symmetric(horizontal:4,vertical:1),child: Text("REAL",style:TextStyle(color:Colors.white,fontSize:7))))])),
              Container(width:1.5,color:Colors.yellow),
              Expanded(child: Stack(children:[ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!))), Positioned(bottom:3,left:3,child: Container(color:Colors.pink,padding:EdgeInsets.symmetric(horizontal:4,vertical:1),child: Text("${selectedFilter}",style:TextStyle(color:Colors.white,fontSize:6))))])),
            ]))
          ])),
          SizedBox(height:4),
          Row(children:[
            SizedBox(height:26, child: ElevatedButton(onPressed: ()=>setState(()=>showComparison=!showComparison), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF222222), padding:EdgeInsets.symmetric(horizontal:10)), child: Text(showComparison?"SINGLE":"COMPARE",style:TextStyle(fontSize:8)))),
            SizedBox(width:6),
            Expanded(child: Container(height:26, padding:EdgeInsets.symmetric(horizontal:6), decoration: BoxDecoration(color:Color(0xFF1A1A1A),borderRadius: BorderRadius.circular(6)), child: Row(children:[Text("${intensity.toInt()}%",style:TextStyle(color:Colors.white.withOpacity(0.6),fontSize:8)), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight:1.5, thumbShape: RoundSliderThumbShape(enabledThumbRadius:4)), child: Slider(value:intensity,min:30,max:50,activeColor:Colors.yellow,inactiveColor:Colors.white.withOpacity(0.2),onChanged:(v)=>setState(()=>intensity=v))))])))
