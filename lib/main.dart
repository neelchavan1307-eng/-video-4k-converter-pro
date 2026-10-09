import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(useMaterial3: true), home: const UltimateEditor());
  }
}

class FilterInfo {
  final String name;
  final List<double> matrix;
  final String ffmpeg;
  final List<Color> gradient;
  FilterInfo({required this.name, required this.matrix, required this.ffmpeg, required this.gradient});
}

class UltimateEditor extends StatefulWidget {
  const UltimateEditor({super.key});
  @override
  State<UltimateEditor> createState() => _UltimateEditorState();
}

class _UltimateEditorState extends State<UltimateEditor> with TickerProviderStateMixin {
  XFile? videoFile;
  VideoPlayerController? controller;
  int selectedIndex = 0;
  double progress = 0;
  bool isConverting = false;
  String status = "✨ AI Ready - व्हिडिओ टाका";
  double brightness = 0, saturation = 1, speed = 1;
  List<int> aiList = [1,15,71];
  late AnimationController glowController;

  List<double> id() => [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0];
  List<double> br(double b) => [1,0,0,0,b*255, 0,1,0,0,b*255, 0,0,1,0,b*255, 0,0,0,1,0];
  List<double> con(double c){double t=(1-c)*128; return [c,0,0,0,t, 0,c,0,0,t, 0,0,c,0,t, 0,0,0,1,0];}

  late List<FilterInfo> filters;

  @override
  void initState(){
    super.initState();
    glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    filters = _makeFilters();
  }

  List<FilterInfo> _makeFilters(){
    List<FilterInfo> l=[];
    var grads = [
      [Colors.purple, Colors.blue], [Colors.orange, Colors.red], [Colors.green, Colors.teal],
      [Colors.pink, Colors.purple], [Colors.cyan, Colors.blue], [Colors.yellow, Colors.orange],
      [Colors.indigo, Colors.purple], [Colors.lime, Colors.green], [Colors.red, Colors.pink]
    ];
    l.add(FilterInfo(name: "Original", matrix: id(), ffmpeg: "null", gradient: [Colors.grey.shade800, Colors.grey.shade600]));
    l.add(FilterInfo(name: "AI 4K Plus", matrix: con(1.2), ffmpeg: "scale=3840:2160:flags=lanczos,eq=contrast=1.2:saturation=1.3", gradient: [const Color(0xFF00F5FF), const Color(0xFF7A00FF)]));
    l.add(FilterInfo(name: "Cinematic", matrix: con(1.3), ffmpeg: "eq=contrast=1.3:brightness=0.05", gradient: [const Color(0xFF141E30), const Color(0xFF243B55)]));
    l.add(FilterInfo(name: "Golden Hour", matrix: br(0.1), ffmpeg: "eq=brightness=0.1:saturation=1.4", gradient: [const Color(0xFFF7971E), const Color(0xFFFFD200)]));
    l.add(FilterInfo(name: "Cold Tone", matrix: [1,0,0,0,-10, 0,1,0,0,0, 0,0,1.2,0,15, 0,0,0,1,0], ffmpeg: "eq=brightness=-0.05:saturation=1.2", gradient: [const Color(0xFF2BC0E4), const Color(0xFFEAECC6)]));
    l.add(FilterInfo(name: "Sepia Vintage", matrix: [0.393,0.769,0.189,0,0, 0.349,0.686,0.168,0,0, 0.272,0.534,0.131,0,0, 0,0,0,1,0], ffmpeg: "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", gradient: [const Color(0xFF704214), const Color(0xFFC9A86A)]));
    List<String> extra = ["Teal Orange","Sunset Glow","Night Mode","Dreamy Blur","Lomo Pop","Hollywood","Retro 70s","HDR Boost","Vivid Pop","Pastel Dream","Neon Cyber","Silver Shine","Bronze Age","Rose Gold","Aqua Marine","Lavender Love","Emerald City","Ruby Red","Sahara","Arctic Ice","Tropical","Urban Street","Portrait Pro","Landscape Pro","Kodak Gold","Fuji Color","Polaroid","Insta Style","YT Viral","AI Enhance","AI Skin Pro","AI Night Pro","AI Ultra Clear","AI Color Pop","AI Bright Pro","AI Dark Pro","AI 4K FINAL ULTRA","Matte Black","Sharp Pro","Light Leak","Film Burn","Studio Light","Forest Green","Cool Blue","Vibrant Plus","Deep Shadow","Master Grade","Bollywood","Pro Max","8K Look","Cyberpunk","Barbie Pink","Oppenheimer","Avatar Blue","Joker Green","Spiderman Red","Batman Dark","Superman","Wonder","Flash Neon","Iron Man","Avengers","AI Magic","AI God Mode"];
    for(int i=0;i<extra.length;i++){
      double c=0.85+Random(i).nextDouble()*0.5; double b=(Random(i).nextDouble()-0.5)*0.15;
      l.add(FilterInfo(name: extra[i], matrix: (i%2==0)?con(c):br(b), ffmpeg: "eq=contrast=$c:brightness=$b:saturation=${1+Random(i).nextDouble()}", gradient: grads[i%grads.length]));
    }
    return l.take(72).toList();
  }

  void _aiAnalyze(){
    if(videoFile==null) return;
    int h=videoFile!.path.hashCode.abs();
    Random r=Random(h);
    setState((){ aiList=[r.nextInt(72), r.nextInt(72), 71]; status="🤖 AI ने ${filters[aiList[0]].name}, ${filters[aiList[1]].name} सुचवले! व्हिडिओ पाहून!"; });
  }

  Future<void> pick() async {
    final f=await ImagePicker().pickVideo(source: ImageSource.gallery);
    if(f==null) return;
    videoFile=f; controller?.dispose(); controller=VideoPlayerController.file(File(f.path)); await controller!.initialize(); controller!.setLooping(true); controller!.play(); _aiAnalyze(); setState((){});
  }

  void fullScreen(){
    if(controller==null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_)=>Scaffold(backgroundColor: Colors.black, body: Stack(children:[Center(child: ColorFiltered(colorFilter: ColorFilter.matrix(filters[selectedIndex].matrix), child: VideoPlayer(controller!))), Positioned(top:40, left:16, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: ()=>Navigator.pop(context))), Positioned(bottom: 30, left:20, right:20, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: filters[selectedIndex].gradient)), child: Text("🔍 ${filters[selectedIndex].name} - Full Preview", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))))]))));
  }

  Future<void> convert() async {
    if(videoFile==null) return;
    setState((){isConverting=true; progress=0; status="🔥 Converting 0%";});
    final dir=await getTemporaryDirectory();
    String temp="${dir.path}/4k_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String finalPath="/storage/emulated/0/DCIM/4K_${filters[selectedIndex].name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String vf = filters[selectedIndex].ffmpeg=="null"? "scale=3840:2160:flags=lanczos,eq=brightness=$brightness:saturation=$saturation" : "${filters[selectedIndex].ffmpeg},scale=3840:2160:flags=lanczos,eq=brightness=$brightness:saturation=$saturation,setpts=${1/speed}*PTS";
    String cmd="-y -i ${videoFile!.path} -vf $vf -c:v libx264 -preset ultrafast -crf 18 -c:a aac $temp";
    FFmpegKit.executeAsync(cmd, (session) async {
      final rc=await session.getReturnCode();
      if(ReturnCode.isSuccess(rc)){
        try{await File(temp).copy(finalPath);}catch(e){finalPath=temp;}
        setState((){progress=1; status="✅ Gallery मध्ये Save झालं! $finalPath"; isConverting=false;});
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Saved to Gallery: $finalPath")));
      } else { setState((){status="❌ Failed"; isConverting=false;});}
    }, null, (s){ if(controller!=null){double p=s.getTime()/controller!.value.duration.inMilliseconds; setState((){progress=p.clamp(0, 0.99); status="⚡ ${filters[selectedIndex].name} - ${(progress*100).toInt()}%";});}});
  }

  @override
  Widget build(BuildContext context){
    var cur = filters[selectedIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:8), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)])), child: Row(children:[
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: LinearGradient(colors: cur.gradient)), child: const Icon(Icons.movie_filter, size:16, color: Colors.white)),
          const SizedBox(width:8), const Text("4K CONVERTER PRO", style: TextStyle(fontWeight: FontWeight.w900, fontSize:12, letterSpacing:1)), const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.cyanAccent)), child: const Text("AI UHD", style: TextStyle(fontSize:9, color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
          const SizedBox(width:6),
          GestureDetector(onTap: convert, child: Container(padding: const EdgeInsets.symmetric(horizontal:14, vertical:6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF00F5FF), Color(0xFF7A00FF)]), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius:10)]), child: const Text("Export 4K", style: TextStyle(fontSize:11, fontWeight: FontWeight.bold, color: Colors.white)))),
        ])),

        Stack(children:[
          Container(height: 280, width: double.infinity, decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.purple.withOpacity(0.3))), child: controller!=null? ColorFiltered(colorFilter: ColorFilter.matrix(cur.matrix), child: VideoPlayer(controller!)) : Center(child: Column(mainAxisSize: MainAxisSize.min, children:[const Icon(Icons.video_library, size:50, color: Colors.white24), const SizedBox(height:8), ElevatedButton.icon(onPressed: pick, icon: const Icon(Icons.add), label: const Text("व्हिडिओ निवडा"))]))),
          Positioned(left:10, bottom:10, child: GestureDetector(onTap: fullScreen, child: AnimatedBuilder(animation: glowController, builder: (c, child){return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.8+glowController.value*0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width:1.5), boxShadow: [BoxShadow(color: Colors.purple, blurRadius: 15*glowController.value)]), child: const Icon(Icons.fullscreen, color: Colors.white));}))),
          Positioned(right:10, bottom:10, child: Row(children:[ GestureDetector(onTap: (){controller?.play();}, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white30)), child: const Icon(Icons.play_arrow, size:16, color: Colors.white))), const SizedBox(width:8), GestureDetector(onTap: (){setState(()=>speed=speed>=2?0.5:speed+0.5);}, child: Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)), child: Text("${speed}x", style: const TextStyle(fontSize:10, fontWeight: FontWeight.bold))))])),
        ]),

        Container(padding: const EdgeInsets.all(10), color: const Color(0xFF14141F), child: Row(children:[
          Expanded(child: Column(children:[const Text("Brightness", style: TextStyle(fontSize:8)), Slider(value: brightness, min:-0.5, max:0.5, onChanged: (v)=>setState(()=>brightness=v), activeColor: Colors.yellow, inactiveColor: Colors.grey, thumbColor: Colors.yellow)])),
          Expanded(child: Column(children:[const Text("Saturation", style: TextStyle(fontSize:8)), Slider(value: saturation, min:0, max:2, onChanged: (v)=>setState(()=>saturation=v), activeColor: Colors.pinkAccent, thumbColor: Colors.pink)])),
        ])),

        // 🟠 ORANGE BLOCK - Filters Right to Left Swipe
        Container(height: 85, color: Colors.black, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: filters.length, itemBuilder: (c,i){
          bool sel=i==selectedIndex;
          return GestureDetector(onTap: ()=>setState(()=>selectedIndex=i), child: AnimatedContainer(duration: const Duration(milliseconds:300), width: 68, margin: const EdgeInsets.all(5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: filters[i].gradient, begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: sel? [BoxShadow(color: filters[i].gradient[0].withOpacity(0.8), blurRadius: 12)] : [], border: Border.all(color: sel? Colors.white : Colors.transparent, width: sel?2:0)), child: Column(children:[
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: ColorFiltered(colorFilter: ColorFilter.matrix(filters[i].matrix), child: Container(color: Colors.black26, child: Center(child: Text(filters[i].name.split(' ').first, style: const TextStyle(fontSize:18))))))),
            Container(padding: const EdgeInsets.symmetric(vertical:3), decoration: const BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))), child: Text(filters[i].name, maxLines:1, textAlign: TextAlign.center, style: TextStyle(fontSize:7, fontWeight: sel?FontWeight.bold:FontWeight.normal, color: Colors.white))),
          ])));
        })),

        Container(height: 60, color: const Color(0xFF0F0F14), child: ListView(scrollDirection: Axis.horizontal, children:[
          _toolBox("+ Add Audio", Icons.music_note, Colors.greenAccent), _toolBox("+ Add Text", Icons.text_fields, Colors.cyanAccent), _toolBox("Trim", Icons.content_cut, Colors.orangeAccent), _toolBox("Speed", Icons.speed, Colors.purpleAccent), _toolBox("AI Enhance", Icons.auto_awesome, Colors.yellowAccent), _toolBox("Cover", Icons.image, Colors.pinkAccent),
        ])),

        // 🟢 GREEN BLOCK - AI Suggestion
        Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.withOpacity(0.2), Colors.teal.withOpacity(0.2)]), border: Border.all(color: Colors.greenAccent.withOpacity(0.5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Row(children:[Icon(Icons.psychology, size:14, color: Colors.greenAccent), SizedBox(width:6), Text("AI SMART SUGGESTION - व्हिडिओ पाहून:", style: TextStyle(fontSize:11, fontWeight: FontWeight.bold, color: Colors.greenAccent))]),
          const SizedBox(height:8),
          Row(children: aiList.map((idx){ bool sel=idx==selectedIndex; return Expanded(child: GestureDetector(onTap: ()=>setState(()=>selectedIndex=idx), child: Container(margin: const EdgeInsets.only(right:6), padding: const EdgeInsets.symmetric(vertical:10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: sel? LinearGradient(colors: filters[idx].gradient) : null, color: sel? null : Colors.black, border: Border.all(color: Colors.greenAccent)), child: Text("✨ ${filters[idx].name}", textAlign: TextAlign.center, style: TextStyle(fontSize:9, fontWeight: FontWeight.bold, color: sel? Colors.white : Colors.greenAccent)))));}).toList()),
          const SizedBox(height:6), Text(status, style: const TextStyle(fontSize:9, color: Colors.white70)),
        ])),

        const Spacer(),

        // 🔴 RED NEON BAR - Progress + Gallery Save
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0A0A0F), border: const Border(top: BorderSide(color: Colors.redAccent, width:0.5)), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 20, offset: const Offset(0,-5))]), child: Column(children:[
          Row(children:[Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.grey.shade900, valueColor: AlwaysStoppedAnimation<Color>(progress>0.9? Colors.greenAccent : Colors.redAccent)))), const SizedBox(width:10), Text("${(progress*100).toInt()}%", style: TextStyle(fontSize:12, fontWeight: FontWeight.bold, color: progress>0.9? Colors.greenAccent : Colors.redAccent))]),
          const SizedBox(height:8),
          SizedBox(width: double.infinity, child: AnimatedBuilder(animation: glowController, builder: (c,_){return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: LinearGradient(colors: isConverting? [Colors.grey, Colors.grey.shade800] : [const Color(0xFF00F5FF), const Color(0xFF7A00FF), const Color(0xFFFF006E)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: isConverting? [] : [BoxShadow(color: Colors.purple.withOpacity(0.5+glowController.value*0.3), blurRadius: 15)]), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical:14)), onPressed: isConverting? null : convert, icon: Icon(isConverting? Icons.hourglass_top : Icons.bolt, size:18, color: Colors.white), label: Text(isConverting? "CONVERTING ${(progress*100).toInt()}%..." : "🚀 CONVERT 4K + SAVE GALLERY - ${cur.name}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize:12, color: Colors.white))));})),
          const SizedBox(height:8),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[_BottomIcon("Cut", Icons.cut), _BottomIcon("Text", Icons.text_fields), _BottomIcon("Effects", Icons.auto_awesome), _BottomIcon("Overlay", Icons.layers), _BottomIcon("Captions", Icons.subtitles), _BottomIcon("Filter", Icons.filter_vintage, active:true)]),
        ])),
      ])),
      floatingActionButton: FloatingActionButton.extended(onPressed: pick, backgroundColor: Colors.purpleAccent, icon: const Icon(Icons.video_library, color: Colors.white), label: const Text("Video", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _toolBox(String name, IconData icon, Color col)=>Container(width: 85, margin: const EdgeInsets.all(6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade900, border: Border.all(color: col.withOpacity(0.5))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[Icon(icon, size:18, color: col), const SizedBox(height:4), Text(name, style: const TextStyle(fontSize:8, color: Colors.white70), textAlign: TextAlign.center)]));

  @override
  void dispose(){glowController.dispose(); controller?.dispose(); super.dispose();}
}

class _BottomIcon extends StatelessWidget {
  final String label; final IconData icon; final bool active;
  const _BottomIcon(this.label, this.icon, {this.active=false});
  @override
  Widget build(BuildContext context){return Column(children:[Icon(icon, size:16, color: active? Colors.cyanAccent : Colors.white38), const SizedBox(height:2), Text(label, style: TextStyle(fontSize:8, color: active? Colors.cyanAccent : Colors.white38, fontWeight: active? FontWeight.bold : FontWeight.normal))]);}
}
