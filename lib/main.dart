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

  // JUNI 6 FEATURES - PARAT ADD KELE
  double focusFilter = 50, fourKFilter = 70, evenSkin = 30, whitening = 25, brilliance = 20, sharpen = 40;
  String selectedMode = "Devi Glow";

  // NAVA CAPCUT 5 CATEGORY
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
      Timer.periodic(Duration(milliseconds: 200), (t){ if(_c!=null && _c!.value.isInitialized) setState(()=> previewProgress = _c!.value.position.inMilliseconds / _c!.value.duration.inMilliseconds); });
      setState(()=> status="Ready");
    }
  }

  List<double> getMatrix(){
    double w = whitening; double i = intensity/50;
    // Base on OLD 3 modes + NEW filter mix
    List<double> base;
    if(selectedMode=="Devi Glow") base=[1.4,0,0,0,15+w, 0,1.2,0,0,10+w, 0,0,0.9,0,-5+w, 0,0,0,1,0];
    else if(selectedMode=="Cute Soft") base=[1.3,0.1,0.1,0,25+w, 0.1,1.2,0.1,0,20+w, 0.1,0.1,1.4,0,30+w, 0,0,0,1,0];
    else base=[1.6,-0.1,0,0,5+w/2, -0.1,1.1,0,0,5+w/2, 0,0,1.8,0,5+w/2, 0,0,0,1,0];

    // CapCut filter intensity mix
    if(selectedFilter=="Oppenheimer") base[0]+=0.1*i;
    if(selectedFilter=="Glow") { base[4]+=20*i; base[9]+=15*i; base[14]+=20*i; }
    if(selectedFilter=="Lunar Night") { base[2]+=0.2*i; }
    return base;
  }

  Future<void> convert() async {
    if(pickedFile==null) return;
    setState((){ processing=true; convertProgress=0.01; });
    FFmpegKitConfig.enableStatisticsCallback((s){ double p = s.getTime() / _c!.value.duration.inMilliseconds; if(p>0.99) p=0.99; setState((){ convertProgress=p; status="${(p*100).toInt()}% ${selectedFilter}"; }); });

    Directory d = Directory("/storage/emulated/0/Movies/HATKE_4K");
    if(!await d.exists()) await d.create(recursive:true);
    String out = "${d.path}/HATKE_${selectedMode}_${selectedFilter}_${DateTime.now().millisecondsSinceEpoch}.mp4";

    double sharpVal = (sharpen + focusFilter)/100 * 1.5;
    bool isPortrait = _c!.value.size.height > _c!.value.size.width;
    String scalePart = isPortrait? "scale=1080:1920:flags=lanczos:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black" : "scale=1920:1080:flags=lanczos:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=black";

    // MERGE: Old 6 filters + New CapCut filter
    String oldVf = "unsharp=5:5:$sharpVal:5:5:0,eq=contrast=${1+brilliance/100}:brightness=${0.02+whitening/400}:saturation=${1.3+fourKFilter/100}";
    String newVf;
    double ii = intensity/100;
    if(selectedFilter=="Oppenheimer") newVf="eq=contrast=${1.2+ii}:saturation=0.8:gamma=1.1";
    else if(selectedFilter=="Quality Boost") newVf="unsharp=5:5:1.0:5:5:0,eq=contrast=${1.1+ii}:saturation=1.3";
    else if(selectedFilter=="Glow") newVf="eq=brightness=${0.05+ii}:saturation=1.4,gblur=sigma=0.3";
    else if(selectedFilter=="Antique") newVf="curves=vintage,eq=saturation=0.7, vignette=PI/4";
    else if(selectedFilter=="Lunar Night") newVf="eq=contrast=1.2:brightness=-0.1:saturation=0.6, colorbalance=bs=0.2";
    else newVf="eq=contrast=${1+ii}:saturation=${1+ii}";

    String finalVf = "$scalePart,$oldVf,$newVf";
    String cmd = "-y -i '${pickedFile!.path}' -vf \"$finalVf\" -c:v libx264 -preset superfast -crf 23 -c:a copy '$out'";

    await FFmpegKit.execute(cmd).then((s) async {
      FFmpegKitConfig.enableStatisticsCallback(null);
      if(ReturnCode.isSuccess(await s.getReturnCode())){ setState((){ convertProgress=1.0; processing=false; status="DONE! $out"; }); }
      else { setState((){ processing=false; status="Failed"; }); }
    });
  }

  Widget modeChip(String n, IconData ic, Color c){ bool sel=selectedMode==n; return GestureDetector(onTap: ()=>setState(()=>selectedMode=n), child: Container(padding: EdgeInsets.symmetric(horizontal:12,vertical:6), decoration: BoxDecoration(color: sel?c:Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: sel?Colors.white:c.withOpacity(0.6))), child: Row(mainAxisSize:MainAxisSize.min,children:[Icon(ic,size:12,color:Colors.white),SizedBox(width:4),Text(n,style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold))]))) ;}
  Widget miniSlider(String n, double v, Function(double) onC){ return Row(children:[SizedBox(width:90,child: Text(n,style:TextStyle(color:Colors.white70,fontSize:10))), Expanded(child: SliderTheme(data: SliderThemeData(trackHeight:2, thumbShape: RoundSliderThumbShape(enabledThumbRadius:6)), child: Slider(value:v,min:0,max:100,activeColor:Colors.pinkAccent,inactiveColor:Colors.white24,onChanged:(vv)=>setState(()=>onC(vv))))), SizedBox(width:28,child: Text("${v.toInt()}",style:TextStyle(color:Colors.pinkAccent,fontSize:10)))]); }

  @override
  Widget build(BuildContext context){
    return Scaffold(backgroundColor: Color(0xFF0A0A0A), appBar: AppBar(title: Text("HATKE 4K - FULL FEATURE"), backgroundColor: Colors.purple),
      body: SingleChildScrollView(padding: EdgeInsets.all(10), child: Column(children:[
        ElevatedButton(onPressed: processing?null:pick, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(double.infinity,44)), child: Text("SELECT VIDEO")),
        if(_c!=null && _c!.value.isInitialized)...[
          SizedBox(height:8),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(children:[
            AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)),
            if(!showComparison) Positioned.fill(child: ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: Container())),
            if(showComparison) Positioned.fill(child: Row(children:[
              Expanded(child: Stack(children:[AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!)), Positioned(bottom:4,left:4,child: Container(color:Colors.black54,padding:EdgeInsets.all(4),child: Text("REAL",style:TextStyle(color:Colors.white,fontSize:9))))])),
              Container(width:2,color:Colors.yellow),
              Expanded(child: Stack(children:[ColorFiltered(colorFilter: ColorFilter.matrix(getMatrix()), child: AspectRatio(aspectRatio: _c!.value.aspectRatio, child: VideoPlayer(_c!))), Positioned(bottom:4,left:4,child: Container(color:Colors.pink,padding:EdgeInsets.all(4),child: Text("${selectedFilter}",style:TextStyle(color:Colors.white,fontSize:8))))])),
            ]))
          ])),
          Row(children:[ Expanded(child: ElevatedButton(onPressed: ()=>setState(()=>showComparison=!showComparison), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF222222)), child: Text(showComparison?"SINGLE":"COMPARE",style:TextStyle(fontSize:10)))), SizedBox(width:8), Expanded(child: Container(padding:EdgeInsets.symmetric(horizontal:8), decoration: BoxDecoration(color:Color(0xFF1A1A1A),borderRadius: BorderRadius.circular(8)), child: Row(children:[Text("${intensity.toInt()}%",style:TextStyle(color:Colors.white70,fontSize:10)), Expanded(child: Slider(value:intensity,min:30,max:50,activeColor:Colors.yellow,onChanged:(v)=>setState(()=>intensity=v)))]))) ]),
          Container(height:14, margin:EdgeInsets.only(top:6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color:Colors.white10), child: Stack(children:[FractionallySizedBox(widthFactor: (processing?convertProgress:previewProgress).clamp(0.0,1.0), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [Colors.purple,Colors.pink,Colors.orange,Colors.yellow])))), if(processing) Center(child: Text("${(convertProgress*100).toInt()}% CONVERTING",style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.bold))) ])),
        ],
        SizedBox(height:10),
        Text("OLD 3 MODES",style:TextStyle(color:Colors.white54,fontSize:10,fontWeight:FontWeight.bold)),
        SizedBox(height:4),
        Row(mainAxisAlignment:MainAxisAlignment.center, children:[modeChip("Devi Glow", Icons.auto_awesome, Colors.orange), SizedBox(width:6), modeChip("Cute Soft", Icons.favorite, Colors.pink), SizedBox(width:6), modeChip("Cyber Pop", Icons.bolt, Colors.cyan)]),
        SizedBox(height:8),
        Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)), child: Column(children:[ miniSlider("Focus", focusFilter, (v)=>focusFilter=v), miniSlider("4K Filter", fourKFilter, (v)=>fourKFilter=v), miniSlider("Even Skin", evenSkin, (v)=>evenSkin=v), miniSlider("Whitening", whitening, (v)=>whitening=v), miniSlider("Brilliance", brilliance, (v)=>brilliance=v), miniSlider("Sharpen", sharpen, (v)=>sharpen=v), ])),
        SizedBox(height:10),
        Text("NEW CAPCUT 5 CATEGORIES",style:TextStyle(color:Colors.yellow,fontSize:10,fontWeight:FontWeight.bold)),
        SizedBox(height:4),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.keys.map((cat){ bool sel=cat==selectedCategory; return GestureDetector(onTap: ()=>setState(()=>selectedCategory=cat), child: Container(margin:EdgeInsets.only(right:6), padding:EdgeInsets.symmetric(horizontal:12,vertical:6), decoration: BoxDecoration(color: sel?Colors.yellow:Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)), child: Text(cat,style:TextStyle(color: sel?Colors.black:Colors.white70,fontSize:10,fontWeight:FontWeight.bold)))); }).toList())),
        SizedBox(height:6),
        Container(padding:EdgeInsets.all(8), decoration: BoxDecoration(color:Color(0xFF151515),borderRadius: BorderRadius.circular(10)), child: Wrap(spacing:5,runSpacing:5, children: categories[selectedCategory]!.map((f){ bool sel=f==selectedFilter; return GestureDetector(onTap: ()=>setState(()=>selectedFilter=f), child: Container(width: (MediaQuery.of(context).size.width-50)/3, padding:EdgeInsets.symmetric(vertical:8), decoration: BoxDecoration(color: sel?Colors.white:Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8), border: sel?Border.all(color:Colors.yellow,width:2):null), child: Column(children:[Icon(Icons.filter, size:16, color: sel?Colors.black:Colors.white54), SizedBox(height:2), Text(f, textAlign:TextAlign.center, style:TextStyle(color: sel?Colors.black:Colors.white70,fontSize:8,fontWeight:FontWeight.bold))]))) ;}).toList())),
        SizedBox(height:10),
        Text(status, style:TextStyle(color:Colors.white70,fontSize:10), textAlign: TextAlign.center),
        SizedBox(height:10),
        ElevatedButton(onPressed: processing?null:convert, style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: Size(double.infinity,48)), child: Text(processing?"${(convertProgress*100).toInt()}% RENDERING":"EXPORT ${selectedMode}+${selectedFilter} @ ${intensity.toInt()}%",style:TextStyle(fontWeight:FontWeight.bold,fontSize:11))),
        SizedBox(height:20),
      ])),
    );
  }
}
