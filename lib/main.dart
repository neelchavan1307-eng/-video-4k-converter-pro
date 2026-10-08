import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green), home: const FilterScreen());
}
class FilterInfo { final String name; final List<double> matrix; final String ffmpeg; final Color color; FilterInfo({required this.name, required this.matrix, required this.ffmpeg, required this.color}); }

class FilterScreen extends StatefulWidget { const FilterScreen({super.key}); @override State<FilterScreen> createState()=> _FilterScreenState(); }
class _FilterScreenState extends State<FilterScreen> {
  XFile? _videoFile; VideoPlayerController? _controller; int _sel=0; bool _conv=false;
  List<double> id()=>[1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0];
  List<double> br(double b)=>[1,0,0,0,b*255, 0,1,0,0,b*255, 0,0,1,0,b*255, 0,0,0,1,0];
  List<double> ct(double c){double t=(1-c)*128; return [c,0,0,0,t, 0,c,0,0,t, 0,0,c,0,t, 0,0,0,1,0];}
  List<double> sepiaM()=>[0.393,0.769,0.189,0,0, 0.349,0.686,0.168,0,0, 0.272,0.534,0.131,0,0, 0,0,0,1,0];
  List<double> grayM()=>[0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0];
  late List<FilterInfo> filters;

  @override void initState(){
    super.initState();
    filters=[];
    filters.add(FilterInfo(name:"1. Original", matrix:id(), ffmpeg:"null", color:Colors.grey.shade300));
    filters.add(FilterInfo(name:"2. 4K Upscale", matrix:ct(1.15), ffmpeg:"scale=3840:2160:flags=lanczos", color:Colors.blueGrey));
    filters.add(FilterInfo(name:"3. Bright +50", matrix:br(0.2), ffmpeg:"eq=brightness=0.1", color:Colors.yellow.shade200));
    filters.add(FilterInfo(name:"4. Dark -30", matrix:br(-0.12), ffmpeg:"eq=brightness=-0.15", color:Colors.brown.shade400));
    filters.add(FilterInfo(name:"5. High Contrast", matrix:ct(1.5), ffmpeg:"eq=contrast=1.5", color:Colors.black87));
    filters.add(FilterInfo(name:"6. Low Contrast", matrix:ct(0.7), ffmpeg:"eq=contrast=0.7", color:Colors.grey.shade500));
    filters.add(FilterInfo(name:"7. Saturation Boost", matrix:[1.3,0,0,0,-20, 0,1.3,0,0,-20, 0,0,1.3,0,-20, 0,0,0,1,0], ffmpeg:"eq=saturation=1.8", color:Colors.pink));
    filters.add(FilterInfo(name:"8. Desaturated", matrix:[0.6,0.2,0.2,0,0, 0.2,0.6,0.2,0,0, 0.2,0.2,0.6,0,0, 0,0,0,1,0], ffmpeg:"eq=saturation=0.3", color:Colors.grey));
    filters.add(FilterInfo(name:"9. Grayscale", matrix:grayM(), ffmpeg:"hue=s=0", color:Colors.black26));
    filters.add(FilterInfo(name:"10. Sepia", matrix:sepiaM(), ffmpeg:"colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", color:Color(0xFF704214)));
    filters.add(FilterInfo(name:"11. Vintage 1", matrix:[1.1,0,0,0,10, 0,1.0,0,0,5, 0,0,0.9,0,0, 0,0,0,1,0], ffmpeg:"curves=vintage", color:Colors.orange.shade300));
    filters.add(FilterInfo(name:"12. Vintage 2", matrix:[0.9,0.1,0,0,15, 0.1,0.9,0,0,10, 0,0,0.8,0,0, 0,0,0,1,0], ffmpeg:"eq=brightness=0.05:saturation=0.8", color:Colors.orange.shade700));
    filters.add(FilterInfo(name:"13. Cinematic", matrix:ct(1.3), ffmpeg:"eq=contrast=1.3:brightness=0.05:saturation=1.2", color:Colors.indigo));
    filters.add(FilterInfo(name:"14. Warm Tone", matrix:[1.2,0,0,0,20, 0,1.05,0,0,10, 0,0,0.9,0,-10, 0,0,0,1,0], ffmpeg:"eq=brightness=0.06:saturation=1.2", color:Colors.deepOrange.shade200));
    filters.add(FilterInfo(name:"15. Cold Tone", matrix:[1,0,0,0,-15, 0,1,0,0,-5, 0,0,1.2,0,20, 0,0,0,1,0], ffmpeg:"eq=brightness=0.02:saturation=1.1", color:Colors.lightBlue.shade200));
    List<String> names=["16. Cool Blue","17. Sunset Glow","18. Forest Green","19. Night Mode","20. Dreamy","21. Lomo","22. Hollywood","23. Retro 70s","24. Faded Film","25. HDR Boost","26. Vivid Pop","27. Soft Light","28. Sharp Pro","29. Moody Dark","30. Teal Orange","31. Cross Process","32. BW High","33. BW Low","34. Neon Glow","35. Pastel","36. Vibrant Plus","37. Matte Finish","38. Deep Tone","39. Light Leak","40. Golden Hour","41. Silver Shine","42. Bronze","43. Rose Gold","44. Aqua Blue","45. Lavender","46. Emerald","47. Ruby Red","48. Sahara","49. Arctic Cold","50. Tropical","51. Urban Street","52. Portrait Pro","53. Landscape Pro","54. Studio Light","55. Film 1","56. Film 2","57. Film 3","58. Kodak Gold","59. Fuji Color","60. Polaroid","61. Insta Filter","62. Snap Style","63. YT Pop","64. AI Enhance","65. AI 4K Plus Pro","66. AI Bright Fix","67. AI Dark Fix","68. AI Color Pop","69. AI Night Clear","70. AI Skin Smooth","71. AI Ultra Clear","72. AI 4K Plus FINAL"];
    for(int i=0;i<names.length;i++){
      double c=0.8 + (i%6)*0.12; double b=((i%7)-3)*0.04;
      List<double> m=i%2==0?ct(c):br(b);
      if(i==names.length-1) m=[1.4,0,0,0,-10, 0,1.4,0,0,-10, 0,0,1.4,0,-10, 0,0,0,1,0];
      String ff=i==names.length-1?"scale=3840:2160:flags=lanczos,eq=contrast=1.4:saturation=1.4:brightness=0.06":"eq=contrast=${c.toStringAsFixed(2)}:brightness=${b.toStringAsFixed(2)}:saturation=1.3";
      filters.add(FilterInfo(name:names[i], matrix:m, ffmpeg:ff, color:Colors.primaries[i%Colors.primaries.length].shade300));
    }
  }
  Future<void> _pick() async { final p=ImagePicker(); final f=await p.pickVideo(source: ImageSource.gallery); if(f==null) return; _videoFile=f; _controller?.dispose(); _controller=VideoPlayerController.file(File(f.path)); await _controller!.initialize(); _controller!.setLooping(true); _controller!.play(); setState((){}); }
  Future<void> _convert() async { if(_videoFile==null) return; setState(()=>_conv=true); final dir=await getTemporaryDirectory(); String out="${dir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.mp4"; String inp=_videoFile!.path; String fl=filters[_sel].ffmpeg; String cmd=fl=="null"?"-i \"$inp\" -c:v libx264 -preset ultrafast -crf 23 -c:a copy \"$out\"":"-i \"$inp\" -vf \"$fl\" -c:v libx264 -preset ultrafast -crf 23 -c:a aac \"$out\""; await FFmpegKit.execute(cmd).then((s) async { final rc=await s.getReturnCode(); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ReturnCode.isSuccess(rc)?"Saved: $out":"Failed"))); }); setState(()=>_conv=false); }
  @override Widget build(BuildContext context){ FilterInfo cur=filters[_sel]; return Scaffold(appBar: AppBar(title: Text("${filters.length} Filters + AI Suggest", style: TextStyle(fontSize:14)), actions: [FilledButton.icon(onPressed:_pick, icon:Icon(Icons.video_library, size:18), label:Text("व्हिडिओ टाका", style:TextStyle(fontSize:12))) ] ), body: Column(children:[ Container(height:260, width:double.infinity, color:Colors.black, child: _controller!=null && _controller!.value.isInitialized? ColorFiltered(colorFilter: ColorFilter.matrix(cur.matrix), child: AspectRatio(aspectRatio:_controller!.value.aspectRatio, child: VideoPlayer(_controller!))) : Center(child: Text("व्हिडिओ निवडा", style:TextStyle(color:Colors.white)))), Padding(padding: EdgeInsets.all(8), child: Row(children:[Expanded(child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text("15. Cold Tone", style:TextStyle(fontWeight:FontWeight.bold, fontSize:12)), Text("Warm आहे - Cold करा", style:TextStyle(fontSize:10))]))), SizedBox(width:8), Expanded(child: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text("72. AI 4K Plus FINAL", style:TextStyle(fontWeight:FontWeight.bold, fontSize:12)), Text("Final Export Best", style:TextStyle(fontSize:10))])))]), ), Padding(padding: EdgeInsets.symmetric(horizontal:12, vertical:4), child: SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(vertical:14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed:_conv?null:_convert, child: _conv? SizedBox(height:20,width:20, child:CircularProgressIndicator(color:Colors.white, strokeWidth:2)) : Text("CONVERT - ${cur.name}", style:TextStyle(fontWeight:FontWeight.bold))))), Padding(padding: EdgeInsets.symmetric(horizontal:12, vertical:4), child: Align(alignment: Alignment.centerLeft, child: Text("सर्व ${filters.length} फिल्टर (आडवा स्लाइड करा 👉):", style:TextStyle(fontWeight:FontWeight.bold, fontSize:13)))), SizedBox(height:115, child: ListView.builder(scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal:12), itemCount: filters.length, itemBuilder: (context,index){ bool sel=index==_sel; FilterInfo f=filters[index]; return GestureDetector(onTap: ()=>setState(()=>_sel=index), child: AnimatedContainer(duration: Duration(milliseconds:200), width:82, margin: EdgeInsets.only(right:10, bottom:8, top:4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: sel?Colors.green:Colors.grey.shade300, width: sel?2.5:1), boxShadow:[BoxShadow(color: Colors.black.withOpacity(sel?0.25:0.12), blurRadius: sel?8:4, offset: Offset(0, sel?4:2))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ Container(height:48, width:58, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: f.color), child: ColorFiltered(colorFilter: ColorFilter.matrix(f.matrix), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(colors:[f.color, f.color.withOpacity(0.6)])), child: Icon(Icons.image, size:22, color: Colors.white70)))), SizedBox(height:6), Padding(padding: EdgeInsets.symmetric(horizontal:4), child: Text(f.name, maxLines:2, textAlign: TextAlign.center, style:TextStyle(fontSize:9, fontWeight: sel?FontWeight.bold:FontWeight.w500))), if(sel) Container(margin: EdgeInsets.only(top:3), height:4,width:18, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10))) ]))); })), ]), ); }
}
