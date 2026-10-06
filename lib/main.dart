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

void main() { runApp(MaterialApp(home: CapCutProApp(), debugShowCheckedModeBanner: false)); }

class CapCutProApp extends StatefulWidget { @override State<CapCutProApp> createState() => _CapCutProAppState(); }

class _CapCutProAppState extends State<CapCutProApp> {
  File? pickedFile;
  VideoPlayerController? _c;
  String status = "Video Select Kara";
  bool processing = false;
  bool showComparison = true;
  double previewProgress = 0;
  double convertProgress = 0;
  double intensity = 40; // 30-50% CapCut rule

  String selectedCategory = "Cinematic";
  String selectedFilter = "Oppenheimer";

  // CapCut Filters as per your video
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
    if (r!= null) {
      pickedFile = File(r.files.single.path!);
      _c?.dispose();
      _c = VideoPlayerController.file(pickedFile!)..initialize().then((_)=>setState((){}))..setLooping(true)..play();
      Timer.periodic(Duration(milliseconds: 200), (t){
        if(_c!=null && _c!.value.isInitialized) setState(()=> previewProgress = _c!.value.position.inMilliseconds / _c!.value.duration.inMilliseconds);
      });
      setState(()=> status="Ready");
    }
  }

  List<double> getFilterMatrix() {
    double i = intensity / 50; // 30-50% rule = 0.6 to 1.0
    switch(selectedFilter){
      case "Green Orange": return [1.2*i,0,0,0,0, 0,1.0,0,0,0, 0,0,0.8*i,0,0, 0,0,0,1,0];
      case "Oppenheimer": return [1.3,0.1,0,0,10*i, 0.05,1.1,0,0,5*i, 0,0,0.9,0,-5*i, 0,0,0,1,0];
      case "Sicily": return [1.4*i,0,0,0,15*i, 0,1.2*i,0,0,10*i, 0,0,0.8,0,0, 0,0,0,1,0];
      case "Wong Kar Wai": return [1.2,0,0,0,5, 0,0.9,0,0,0, 0,0,1.1*i,0,10*i, 0,0,0,1,0];
      case "Quality Boost": return [1.2*i,0,0,0,10*i, 0,1.2*i,0,0,10*i, 0,0,1.2*i,0,10*i, 0,0,0,1,0];
      case "HD Skin": return [1.1,0.05,0.05,0,15*i, 0.05,1.1,0.05,0,10*i, 0.05,0.05,1.2,0,15*i, 0,0,0,1,0];
      case "Film CCD": return [1.3*i,0,0,0,5, 0,1.3*i,0,0,5, 0,0,1.0,0,0, 0,0,0,1,0];
      case "Glow": return [1.2,0.1,0.1,0,20*i, 0.1,1.2,0.1,0,15*i, 0.1,0.1,1.3,0,20*i, 0,0,0,1,0];
      case "Antique": return [1.2*i,0,0,0,10, 0,1.0,0,0,5, 0,0,0.7*i,0,-10, 0,0,0,1,0];
      case "Retro Film": return [1.1,0.1,0,0,0, 0.1,1.0,0,0,0, 0,0,0.8,0,0, 0,0,0,1,0];
      case "Lunar Night": return [0.9*i,0,0,0,0, 0,0.9*i,0,0,0, 0,0,1.3*i,0,10*i, 0,0,0,1,0];
      case "Midnight": return [0.8,0,0,0,0, 0,0.8,0,0,0, 0,0,1.2*i,0,5, 0,0,0,1,0];
      default: return [1.0+0.2*i,0,0,0,10*i, 0,1.0+0.2*i,0,0,10*i, 0,0,1.0+0.2*i,0,10*i, 0,0,0,1,0];
    }
  }

  String getFFmpegFilter(){
    double i = intensity/100;
    switch(selectedFilter){
      case "Oppenheimer": return "eq=contrast=${1.2+i}:brightness=${-0.05}:saturation=${0.8}:gamma=1.1";
      case "Quality Boost": return "unsharp=5:5:1.0:5:5:0,eq=contrast=${1.1+i}:brightness=0.02:saturation=1.3,scale=1080:1920:flags=lanczos:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2";
      case "Glow": return "eq=contrast=${1.0}:brightness=${0.05+i}:saturation=${1.4},gblur=sigma=0.5,eq=brightness=0.05";
      case "Antique": return "curves=vintage,eq=contrast=0.9:brightness=-0.05:saturation=0.7, vignette=angle=PI/4";
      case "Lunar Night": return "eq=contrast=1.2:brightness=-0.1:saturation=0.6:gamma_b=1.3, colorbalance=bs=0.2";
      default: return "eq=contrast=${1+i}:brightness=${i*0.1}:saturation=${1+i}";
    }
  }

  Future<void> convert() async {
    if(pickedFile==null) return;
    setState((){ processing=true; convertProgress=0.01; status="1% Starting..."; });
    FFmpegKitConfig.enableStatisticsCallback((s){
      double p = s.getTime() / _c!.value.duration.inMilliseconds;
      if(p>0.99) p=0.99;
      setState((){ convertProgress=p; status="${(p*100).toInt()}% ${selectedFilter} Applying..."; });
    });

    Directory d = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if(!await d.exists()) await d.create(recursive:true);
    String out = "${d.path}/CAPCUT_${selectedFilter}_${DateTime.now().millisecondsSinceEpoch}.mp4";

    bool isPortrait = _c!.value.size.height > _c!.value.size.width;
    String scalePart = isPortrait ? "scale=1080:1920:flags=lanczos:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" : "scale=1920:1080:flags=lanczos:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2";

    String finalFilter = "$scalePart,${getFFmpegFilter()}";
    String cmd = "-y -i '${pickedFile!.path}' -vf \"$finalFilter\" -c:v libx264 -preset superfast -crf 23 -c:a copy '$out'";

    await FFmpegKit.execute(cmd).then((s) async {
      FFmpegKitConfig.enableStatisticsCallback(null);
      if(ReturnCode.isSuccess(await s.getReturnCode())){
        setState((){ convertProgress=1.0; processing=false; status="DONE! Saved: $out\nFilter: $selectedFilter @ ${intensity.toInt()}%"; });
      } else { setState((){ processing=false; status="Failed"; }); }
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(backgroundColor: Color(0xFF0A0A0A), appBar: AppBar(title: Text("CapCut Pro - 30 Sec Game"), backgroundColor: Colors.black, actions:[Icon(Icons.star, color: Colors.yellow)]),
      body: SingleChildScrollView(padding: EdgeInsets.all(10), child: Column(children:[
        ElevatedButton(onPressed: processing?null:pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity,44)), child: Text("SELECT VIDEO")),
        if(_c!=null && _c!.value.isInitialized)...[
          SizedBox(height:8),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(children:[
            AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)),
            if(!showComparison) Positioned.fill(child: ColorFiltered(colorFilter: ColorFilter.matrix(getFilterMatrix()), child: Container())),
            if(showComparison) Positioned.fill(child: Row(children:[
              Expanded(child: Stack(children:[AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)), Positioned(bottom:4,left:4,child: Container(color:Colors.black54,padding:EdgeInsets.all(4),child: Text("REAL",style:TextStyle(color:Colors.white,fontSize:9))))])),
              Container(width:2,color:Colors.yellow),
              Expanded(child: Stack(children:[ColorFiltered(colorFilter: ColorFilter.matrix(getFilterMatrix()), child: AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!))), Positioned(bottom:4,left:4,child: Container(color:Colors.pink,padding:EdgeInsets.all(4),child: Text("FILTERED",style:TextStyle(color:Colors.white,fontSize:9))))])),
            ]))
          ])),
          SizedBox(height:6),
          Row(children:[
            Expanded(child: ElevatedButton(onPressed: ()=>setState(()=>showComparison=!showComparison), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF222222)), child: Text(showComparison?"SINGLE":"COMPARE",style:TextStyle(fontSize:10)))),
            SizedBox(width:8),
            Expanded(child: Container(padding:EdgeInsets.symmetric(horizontal:10), decoration: BoxDecoration(color:Color(0xFF1A1A1A),borderRadius: BorderRadius.circular(8)), child: Row(children:[Text("Intensity ${intensity.toInt()}%",style:TextStyle(color:Colors.white70,fontSize:10)), Expanded(child: Slider(value:intensity,min:30,max:50,activeColor:Colors.yellow,onChanged:(v)=>setState(()=>intensity=v)))])))
          ]),
          Container(height:16, margin:EdgeInsets.only(top:8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color:Colors.white10), child: Stack(children:[
            FractionallySizedBox(widthFactor: (processing?convertProgress:previewProgress).clamp(0.0,1.0), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Colors.purple,Colors.pink,Colors.orange,Colors.yellow])))),
            if(processing) Center(child: Text("${(convertProgress*100).toInt()}% CONVERTING",style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold))),
          ])),
        ],
        SizedBox(height:12),
        // Category Tabs like CapCut
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.keys.map((cat){
          bool sel = cat==selectedCategory;
          return GestureDetector(onTap: ()=>setState(()=>selectedCategory=cat), child: Container(margin:EdgeInsets.only(right:8), padding:EdgeInsets.symmetric(horizontal:14,vertical:8), decoration: BoxDecoration(color: sel?Colors.yellow:Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)), child: Text(cat,style:TextStyle(color: sel?Colors.black:Colors.white70,fontSize:11,fontWeight:FontWeight.bold))));
        }).toList())),
        SizedBox(height:8),
        // Filters Grid like CapCut
        Container(padding:EdgeInsets.all(8), decoration: BoxDecoration(color:Color(0xFF151515),borderRadius: BorderRadius.circular(12)), child: Wrap(spacing:6,runSpacing:6, children: categories[selectedCategory]!.map((f){
          bool sel = f==selectedFilter;
          return GestureDetector(onTap: ()=>setState(()=>selectedFilter=f), child: Container(width: (MediaQuery.of(context).size.width-60)/3, padding:EdgeInsets.symmetric(vertical:10), decoration: BoxDecoration(color: sel?Colors.white:Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8), border: sel?Border.all(color:Colors.yellow,width:2):null), child: Column(children:[Icon(Icons.filter_vintage, size:18, color: sel?Colors.black:Colors.white54), SizedBox(height:4), Text(f, textAlign:TextAlign.center, style:TextStyle(color: sel?Colors.black:Colors.white70,fontSize:9,fontWeight:FontWeight.bold))])));
        }).toList())),
        SizedBox(height:12),
        Text(status, style:TextStyle(color:Colors.white70,fontSize:11), textAlign: TextAlign.center),
        SizedBox(height:12),
        ElevatedButton(onPressed: processing?null:convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: Size(double.infinity,50)), child: Text(processing?"${(convertProgress*100).toInt()}% RENDERING":"EXPORT ${selectedFilter.toUpperCase()} @ ${intensity.toInt()}%",style:TextStyle(fontWeight:FontWeight.bold))),
        SizedBox(height:20),
      ])),
    );
  }
}
