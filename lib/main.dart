// FINAL: 70 Filters + AI Video Based Suggest
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image/image.dart' as img;

void main()=>runApp(const MaterialApp(debugShowCheckedModeBanner:false, home:HomeScreen()));
class HomeScreen extends StatefulWidget{const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState();}

class _HomeScreenState extends State<HomeScreen>{
  File? video; Uint8List? thumb; bool busy=false;
  String log="व्हिडिओ टाका - AI 70 पैकी Best सुचवेल";
  String selected="1. Original";
  List<Map<String,String>> aiSug=[]; // {filter, reason}

  final Map<String,String> filters={
  "1. Original":"", "2. 4K Upscale":"scale=3840:2160:flags=lanczos", "3. Bright +30":"eq=brightness=0.3", "4. Dark -30":"eq=brightness=-0.3", "5. High Contrast":"eq=contrast=1.5", "6. Low Contrast":"eq=contrast=0.5", "7. Saturation Boost":"eq=saturation=2.0", "8. Desaturated":"eq=saturation=0.3", "9. Grayscale":"hue=s=0", "10. Sepia":"colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", "11. Vintage 1":"curves=vintage", "12. Vintage 2":"colorchannelmixer=.4:.4:.4:0:.2:.6:.2:0:.1:.1:.6", "13. Cinematic":"eq=contrast=1.3:saturation=1.2", "14. Warm Tone":"eq=brightness=0.05:temperature=0.5", "15. Cold Tone":"eq=temperature=-0.5", "16. Blur Soft":"gblur=sigma=2", "17. Blur Heavy":"gblur=sigma=10", "18. Sharpen":"unsharp=5:5:1.0:5:5:0.0", "19. Invert":"negate", "20. Mirror":"hflip", "21. VHS":"noise=alls=20:allf=t", "22. Old Film":"curves=strong_contrast,noise=alls=10", "23. HDR Vivid":"eq=contrast=1.4:saturation=1.6:brightness=0.05", "24. Golden Hour":"eq=temperature=0.8:saturation=1.3:brightness=0.1", "25. Sunset":"colorchannelmixer=1.2:.3:.1:0:.2:1:.1:0:.1:.2:1.1", "26. Sunrise":"eq=temperature=0.7:brightness=0.2:saturation=1.2", "27. Ocean Blue":"colorbalance=bs=0.3", "28. Forest Green":"colorbalance=gs=0.3", "29. Rose Pink":"colorbalance=rs=0.3:bs=0.1", "30. Bollywood Vivid":"eq=saturation=1.8:contrast=1.2:brightness=0.05", "31. Bollywood Drama":"eq=contrast=1.4:saturation=0.8:temperature=0.3", "32. Lomo":"eq=contrast=1.3:saturation=1.4,vignette=angle=PI/4", "33. Vignette":"vignette=angle=PI/4", "34. Night Vision":"colorchannelmixer=.1:.6:.1:0:.2:.7:.2:0:.1:.6:.1", "35. Silver":"hue=s=0,eq=brightness=0.2:contrast=1.1", "36. Noir":"hue=s=0,eq=contrast=1.8:brightness=0.1", "37. Cartoon":"edgedetect=low=0.1:high=0.4", "38. Emboss":"edgedetect,negate", "39. Pencil":"edgedetect,negate,eq=contrast=2", "40. Pixelate":"scale=iw/10:ih/10:flags=neighbor,scale=10*iw:10*ih:flags=neighbor", "41. Dreamy":"gblur=sigma=1.5,eq=brightness=0.1:saturation=1.2", "42. Soft Light":"eq=contrast=0.8:brightness=0.15", "43. Hard Light":"eq=contrast=1.8:brightness=-0.05", "44. Cyberpunk":"eq=saturation=1.5:contrast=1.3", "45. Matrix Green":"colorchannelmixer=0:.5:0:0:.2:.8:.2:0:0:.3:0", "46. 8mm Film":"noise=alls=30:allf=t,eq=contrast=1.1:saturation=0.8", "47. Clarendon":"eq=contrast=1.2:saturation=1.35:brightness=0.05", "48. Gingham":"eq=contrast=0.9:brightness=0.1", "49. Moon":"hue=s=0,eq=contrast=1.1:brightness=0.1", "50. Lark":"eq=brightness=0.1:saturation=1.2:contrast=0.9", "51. Cool Blue":"colorbalance=bs=0.4:gs=0.1", "52. Warm Red":"colorbalance=rs=0.4:gs=-0.1:bs=-0.1", "53. Cross Process":"curves=cross_process", "54. Sin City":"hue=s=0,eq=contrast=1.5", "55. HDR":"eq=contrast=1.3:brightness=0.1:saturation=1.3", "56. Super Saturated":"eq=saturation=3.0", "57. Fast Motion":"setpts=0.5*PTS", "58. Slow Motion":"setpts=2*PTS", "59. Edge Glow":"edgedetect=mode=colormix", "60. Comic":"edgedetect=mode=wires", "61. 60fps":"minterpolate=fps=60:mi_mode=mci", "62. Rotate 90":"transpose=1", "63. Flip Vertical":"vflip", "64. Slow Blur":"tmix=frames=5", "65. Teal Orange":"colorbalance=rs=-0.1:bs=0.2", "66. AI Enhance":"scale=3840:2160:flags=lanczos,unsharp=5:5:1.0,eq=contrast=1.1", "67. AI 4K HDR":"scale=3840:2160:flags=lanczos,eq=contrast=1.2:saturation=1.3:brightness=0.05,unsharp", "68. AI Clear":"scale=3840:2160:flags=lanczos,unsharp=7:7:1.5", "69. AI Bollywood":"scale=3840:2160:flags=lanczos,eq=saturation=1.8:contrast=1.2:temperature=0.2", "70. AI Cinematic 4K":"scale=3840:2160:flags=lanczos,eq=contrast=1.3:saturation=1.2,vignette=angle=PI/4", "71. AI Super HDR":"scale=3840:2160:flags=lanczos,eq=contrast=1.4:saturation=1.6:brightness=0.05", "72. AI 4K Plus":"scale=3840:2160:flags=lanczos,eq=contrast=1.2:saturation=1.4:brightness=0.1,unsharp",
  };

  pickVideo() async {
    var r=await FilePicker.platform.pickFiles(type:FileType.video);
    if(r==null) return;
    video=File(r.files.single.path!);
    setState((){log="AI Analyze करतोय..."; aiSug=[];});
    final t=await VideoThumbnail.thumbnailData(video:video!.path, imageFormat:ImageFormat.JPEG, quality:25);
    if(t==null) return; thumb=t;
    final dec=img.decodeImage(t)!; int lum=0, rC=0, gC=0, bC=0, cnt=0, darkPix=0, brightPix=0;
    for(int y=0; y<dec.height; y+=15){ for(int x=0; x<dec.width; x+=15){
      var p=dec.getPixel(x,y); int l=(0.299*p.r+0.587*p.g+0.114*p.b).toInt();
      lum+=l; rC+=p.r.toInt(); gC+=p.g.toInt(); bC+=p.b.toInt(); if(l<70) darkPix++; if(l>200) brightPix++; cnt++;
    }}
    double avgBright=lum/cnt; double avgR=rC/cnt, avgG=gC/cnt, avgB=bC/cnt;
    double darkRatio=darkPix/cnt; double brightRatio=brightPix/cnt;
    double sat=( (avgR-avgG).abs() + (avgG-avgB).abs() + (avgB-avgR).abs() ) /3;

    List<Map<String,String>> sug=[];
    if(avgBright<95 || darkRatio>0.4){
      sug.add({"filter":"3. Bright +30", "reason":"व्हिडिओ खूप Dark आहे - Bright लावा"});
      sug.add({"filter":"66. AI Enhance", "reason":"Dark व्हिडिओला 4K Clear करेल"});
      sug.add({"filter":"23. HDR Vivid", "reason":"अंधारात Detail आणेल"});
    }
    if(avgBright>185 || brightRatio>0.4){
      sug.add({"filter":"13. Cinematic", "reason":"जास्त Bright आहे - Cinematic ने Balance होईल"});
      sug.add({"filter":"4. Dark -30", "reason":"Brightness कमी करण्यासाठी"});
    }
    if(sat<25){
      sug.add({"filter":"7. Saturation Boost", "reason":"Color फिके आहेत - Color वाढवा"});
      sug.add({"filter":"30. Bollywood Vivid", "reason":"हा फिल्टर कलरफुल करेल - Bollywood Style"});
    }
    if(avgB>avgR+15){
      sug.add({"filter":"14. Warm Tone", "reason":"व्हिडिओ थंड (Blue) वाटतोय - Warm करा"});
      sug.add({"filter":"24. Golden Hour", "reason":"Golden Hour सारखा Warm Effect"});
    }
    if(avgR>avgB+20){
      sug.add({"filter":"15. Cold Tone", "reason":"व्हिडिओ जास्त Warm आहे - थोडा Cold करा"});
    }
    if(sug.isEmpty){
      sug.add({"filter":"70. AI Cinematic 4K", "reason":"Overall Best - 4K Cinematic Look"});
      sug.add({"filter":"67. AI 4K HDR", "reason":"AI HDR ने Quality वाढेल"});
      sug.add({"filter":"30. Bollywood Vivid", "reason":"Vibrant कलर साठी Best"});
    }
    // Always add 4K
    sug.add({"filter":"72. AI 4K Plus", "reason":"Final Export साठी 4K Plus Best आहे"});

    setState((){
      aiSug=sug.toSet().toList().take(5).toList(); // 5 best
      selected=aiSug.first["filter"]!;
      log="AI ने व्हिडिओ पाहिला (Brightness ${avgBright.toInt()}%) - खाली 5 Best सुचवले आहेत 👇";
    });
  }

  convert() async {
    if(video==null) return; setState((){busy=true; log="⏳ ${selected} Apply होतोय...";});
    var dir=await getTemporaryDirectory(); var out="${dir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String vf=filters[selected]!; String cmd="-y -i ${video!.path} ${vf.isEmpty?"":"-vf \"$vf\""} -c:v libx264 -crf 18 -preset ultrafast -c:a aac $out";
    await FFmpegKit.executeAsync(cmd, (s) async { var c=await s.getReturnCode(); if(ReturnCode.isSuccess(c)){ setState((){busy=false; log="✅ DONE! ${selected} Proper Apply झाला\nFile: $out";}); } else { setState((){busy=false; log="❌ Error";}); } });
  }

  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:Text("70 Filters + AI Suggest")), body:ListView(padding:EdgeInsets.all(12), children:[
      ElevatedButton.icon(icon:Icon(Icons.video_library), label:Text("व्हिडिओ टाका"), onPressed:pickVideo),
      if(thumb!=null) ClipRRect(borderRadius:BorderRadius.circular(10), child:Image.memory(thumb!, height:200, fit:BoxFit.cover)),
      SizedBox(height:8), Container(padding:EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.white10, borderRadius:BorderRadius.circular(8)), child:Text(log, style:TextStyle(fontWeight:FontWeight.w500))),
      if(aiSug.isNotEmpty)...[
        SizedBox(height:12), Text("✨ AI सांगतंय - हे फिल्टर लावा:", style:TextStyle(color:Colors.greenAccent, fontWeight:FontWeight.bold, fontSize:16)),
        SizedBox(height:6),
       ...aiSug.map((m)=>Card(color:Colors.green.withOpacity(0.15), child:ListTile(leading:Icon(Icons.auto_awesome, color:Colors.yellow), title:Text(m["filter"]!, style:TextStyle(fontWeight:FontWeight.bold)), subtitle:Text(m["reason"]!), trailing:selected==m["filter"]?Icon(Icons.check_circle, color:Colors.green):null, onTap:()=>setState(()=>selected=m["filter"]!)))),
        Divider(),
      ],
      if(busy) LinearProgressIndicator(),
      ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.green, padding:EdgeInsets.all(16)), onPressed:busy?null:convert, child:Text(busy?"Processing...":"CONVERT - ${selected}", style:TextStyle(fontSize:16))),
      SizedBox(height:10), Text("सर्व 72 फिल्टर:", style:TextStyle(fontWeight:FontWeight.bold)),
     ...filters.keys.map((k)=>ListTile(dense:true, title:Text(k, style:TextStyle(fontSize:13)), selected:k==selected, selectedColor:Colors.greenAccent, onTap:()=>setState(()=>selected=k))),
    ]));
  }
}
