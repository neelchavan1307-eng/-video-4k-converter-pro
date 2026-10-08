import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image/image.dart' as img;

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? videoFile;
  Uint8List? thumb;
  bool isProcessing = false;
  String log = "व्हिडिओ निवडा";
  String selected = "1. Original";
  List<String> suggested = [];
  double progress = 0;

  final Map<String, String> filters = {
    "1. Original": "",
    "2. 4K Upscale": "scale=3840:2160:flags=lanczos",
    "3. Bright +30": "eq=brightness=0.3",
    "4. Dark -30": "eq=brightness=-0.3",
    "5. High Contrast": "eq=contrast=1.5",
    "6. Low Contrast": "eq=contrast=0.5",
    "7. Saturation Boost": "eq=saturation=2.0",
    "8. Desaturated": "eq=saturation=0.3",
    "9. Grayscale": "hue=s=0",
    "10. Sepia": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131",
    "11. Vintage 1": "curves=vintage",
    "12. Vintage 2": "colorchannelmixer=.4:.4:.4:0:.2:.6:.2:0:.1:.1:.6",
    "13. Cinematic": "eq=contrast=1.3:saturation=1.2",
    "14. Warm Tone": "eq=brightness=0.05:temperature=0.5",
    "15. Cold Tone": "eq=temperature=-0.5",
    "16. Blur Soft": "gblur=sigma=2",
    "17. Blur Heavy": "gblur=sigma=10",
    "18. Sharpen": "unsharp=5:5:1.0:5:5:0.0",
    "19. Invert": "negate",
    "20. Mirror": "hflip",
    "21. VHS": "noise=alls=20:allf=t",
    "22. Old Film": "curves=strong_contrast,noise=alls=10",
    "23. HDR Vivid": "eq=contrast=1.4:saturation=1.6:brightness=0.05",
    "24. Golden Hour": "eq=temperature=0.8:saturation=1.3:brightness=0.1",
    "25. Sunset": "colorchannelmixer=1.2:.3:.1:0:.2:1:.1:0:.1:.2:1.1",
    "26. Sunrise": "eq=temperature=0.7:brightness=0.2:saturation=1.2",
    "27. Ocean Blue": "colorbalance=bs=0.3:rs=-0.1",
    "28. Forest Green": "colorbalance=gs=0.3",
    "29. Rose Pink": "colorbalance=rs=0.3:bs=0.1",
    "30. Bollywood Vivid": "eq=saturation=1.8:contrast=1.2:brightness=0.05",
    "31. Bollywood Drama": "eq=contrast=1.4:saturation=0.8:temperature=0.3",
    "32. Lomo": "eq=contrast=1.3:saturation=1.4,vignette=angle=PI/4",
    "33. Vignette": "vignette=angle=PI/4",
    "34. Night Vision": "colorchannelmixer=.1:.6:.1:0:.2:.7:.2:0:.1:.6:.1",
    "35. Thermal": "lut3d=file=thermal",
    "36. Cartoon": "edgedetect=low=0.1:high=0.4",
    "37. Emboss": "convolution=-2 -1 0 -1 1 1 0 1 2:0:0:0:0:0:0:0:0:4:1:128:128",
    "38. Pencil Sketch": "edgedetect,negate,eq=contrast=2",
    "39. Pixelate": "scale=iw/10:ih/10:flags=neighbor,scale=10*iw:10*ih:flags=neighbor",
    "40. Dreamy": "gblur=sigma=1.5,eq=brightness=0.1:saturation=1.2",
    "41. Soft Light": "eq=contrast=0.8:brightness=0.15:saturation=1.1",
    "42. Hard Light": "eq=contrast=1.8:brightness=-0.05",
    "43. Cyberpunk": "eq=saturation=1.5:contrast=1.3,colorchannelmixer=.7:.3:0:0:.2:.8:.2:0:0:.3:.7",
    "44. Matrix Green": "colorchannelmixer=0:.5:0:0:.2:.8:.2:0:0:.3:0",
    "45. 8mm Film": "noise=alls=30:allf=t,eq=contrast=1.1:saturation=0.8",
    "46. Silver": "hue=s=0,eq=brightness=0.2:contrast=1.1",
    "47. Noir": "hue=s=0,eq=contrast=1.8:brightness=0.1",
    "48. Clarendon": "eq=contrast=1.2:saturation=1.35:brightness=0.05",
    "49. Gingham": "eq=contrast=0.9:brightness=0.1",
    "50. Moon": "hue=s=0,eq=contrast=1.1:brightness=0.1",
    "51. Lark": "eq=brightness=0.1:saturation=1.2:contrast=0.9",
    "52. Cool Blue": "colorbalance=bs=0.4:gs=0.1",
    "53. Warm Red": "colorbalance=rs=0.4:gs=-0.1:bs=-0.1",
    "54. Cross Process": "curves=cross_process",
    "55. Sin City": "hue=s=0:0,colorchannelmixer=1.2:0:0:0:0:0:0",
    "56. HDR": "eq=contrast=1.3:brightness=0.1:saturation=1.3",
    "57. Super Saturated": "eq=saturation=3.0",
    "58. Fast Motion": "setpts=0.5*PTS",
    "59. Slow Motion": "setpts=2*PTS",
    "60. Edge Glow": "edgedetect=mode=colormix:high=0",
    "61. Comic": "edgedetect=mode=wires:low=0.1:high=0.4",
    "62. 60fps Smooth": "minterpolate=fps=60:mi_mode=mci",
    "63. Rotate 90": "transpose=1",
    "64. Flip Vertical": "vflip",
    "65. Slow Blur": "tmix=frames=5:weights=1 1 1 1 1",
    "66. Teal Orange": "colorbalance=rs=-0.1:bs=0.2:gs=0.05",
    "67. AI Enhance": "scale=3840:2160:flags=lanczos,unsharp=5:5:1.0,eq=contrast=1.1:saturation=1.1",
    "68. AI 4K HDR": "scale=3840:2160:flags=lanczos,eq=contrast=1.2:saturation=1.3:brightness=0.05,unsharp",
    "69. AI Clear": "scale=3840:2160:flags=lanczos,unsharp=7:7:1.5,eq=brightness=0.05",
    "70. AI Bollywood": "scale=3840:2160:flags=lanczos,eq=saturation=1.8:contrast=1.2:temperature=0.2:brightness=0.05",
    "71. AI Cinematic 4K": "scale=3840:2160:flags=lanczos,eq=contrast=1.3:saturation=1.2,vignette=angle=PI/4,unsharp",
    "72. AI Super HDR": "scale=3840:2160:flags=lanczos,eq=contrast=1.4:saturation=1.6:brightness=0.05,unsharp",
  };

  Future<void> pickVideo() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.video);
    if(res==null) return;
    videoFile = File(res.files.single.path!);
    log = "Analyzing: ${res.files.single.name}";
    setState((){});
    await analyzeVideo();
  }

  Future<void> analyzeVideo() async {
    if(videoFile==null) return;
    final t = await VideoThumbnail.thumbnailData(video: videoFile!.path, imageFormat: ImageFormat.JPEG, quality: 30);
    if(t==null) return;
    thumb = t;
    final decoded = img.decodeImage(t)!;
    int lum=0, r=0,g=0,b=0, count=0;
    for(int y=0; y<decoded.height; y+=15){
      for(int x=0; x<decoded.width; x+=15){
        final p = decoded.getPixel(x, y);
        lum += (0.299*p.r + 0.587*p.g + 0.114*p.b).toInt();
        r+=p.r.toInt(); g+=p.g.toInt(); b+=p.b.toInt(); count++;
      }
    }
    double bright = lum/count;
    List<String> sug = [];
    String rep = "";
    if(bright < 90){ rep+="🔅 Dark आहे -> Bright, HDR, AI Enhance Best\n"; sug.addAll(["3. Bright +30","23. HDR Vivid","67. AI Enhance","24. Golden Hour"]);} 
    else if(bright>190){ rep+="☀️ जास्त Bright आहे -> Dark, Cinematic Best\n"; sug.addAll(["4. Dark -30","13. Cinematic","47. Noir"]);} 
    else { rep+="✅ Brightness Perfect\n"; sug.addAll(["13. Cinematic","30. Bollywood Vivid","67. AI Enhance"]); }
    if((r-g).abs()<15 && (g-b).abs()<15){ rep+="⚪ Color कमी आहे\n"; sug.addAll(["7. Saturation Boost","25. Sunset","30. Bollywood Vivid"]);}
    if(r>b+20) sug.add("15. Cold Tone");
    if(b>r+20) sug.add("14. Warm Tone");
    setState((){ suggested=sug.toSet().take(6).toList(); log=rep; selected=suggested.first; });
  }

  Future<void> convert() async {
    if(videoFile==null) return;
    setState((){ isProcessing=true; progress=0; log="Converting..."; });
    final dir = await getTemporaryDirectory();
    final outPath = "${dir.path}/4K_${DateTime.now().millisecondsSinceEpoch}.mp4";
    String vf = filters[selected]!;
    String cmd = "-y -i ${videoFile!.path} ${vf.isEmpty ? "" : "-vf \"$vf\""} -c:v libx264 -crf 18 -preset ultrafast -c:a aac $outPath";
    
    await FFmpegKit.executeAsync(cmd, (session) async {
      final code = await session.getReturnCode();
      if(ReturnCode.isSuccess(code)){
        setState((){ isProcessing=false; log="✅ SUCCESS!\nSaved: $outPath\nFilter: $selected Properly Applied!"; });
      } else {
        final fail = await session.getFailStackTrace();
        setState((){ isProcessing=false; log="❌ Failed: $fail\nCMD: $cmd"; });
      }
    }, (log) {}, (stats){
      setState(()=> progress = stats.getProgress() / 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("72 Filters - Proper Apply (${filters.length})")),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        ElevatedButton.icon(onPressed: pickVideo, icon: const Icon(Icons.video_library), label: const Text("व्हिडिओ निवडा")),
        if(thumb!=null) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Image.memory(thumb!, height: 180, fit: BoxFit.cover)),
        Text(log, style: const TextStyle(fontSize: 14)),
        if(suggested.isNotEmpty)...[
          const SizedBox(height: 10),
          const Text("✨ AI Suggest (Video नुसार):", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          Wrap(spacing: 6, children: suggested.map((e)=>ChoiceChip(label: Text(e, style: const TextStyle(fontSize: 11)), selected: selected==e, onSelected: (_)=>setState(()=>selected=e))).toList()),
        ],
        const SizedBox(height: 10),
        if(isProcessing) LinearProgressIndicator(value: progress>0?progress:null),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: isProcessing?null:convert, child: Text(isProcessing?"Processing ${(progress*100).toStringAsFixed(0)}%":"CONVERT to 4K with $selected"))),
        const Divider(),
        const Text("सर्व 72 Filters (Tap to Apply):"),
        ...filters.keys.map((k)=>ListTile(dense:true, title: Text(k, style: const TextStyle(fontSize: 13)), selected: k==selected, trailing: suggested.contains(k)?const Icon(Icons.auto_awesome, color: Colors.yellow, size: 16):null, onTap: ()=>setState(()=>selected=k))),
      ]),
    );
  }
}
