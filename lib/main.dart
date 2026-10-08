import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image/image.dart' as img;

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAnalyzing = false;
  String analysis = "व्हिडिओ Analyze करा - AI 72 पैकी Best 6 सुचवेल";
  List<String> suggested = [];
  String selected = "1. Original";
  Uint8List? thumb;

  final Map<String, String> allFilters = {
    "1. Original": "", "2. 4K Upscale": "scale=3840:2160", "3. Bright +30": "eq=brightness=0.3",
    "4. Dark -30": "eq=brightness=-0.3", "5. High Contrast": "eq=contrast=1.5",
    "6. Low Contrast": "eq=contrast=0.5", "7. Saturation Boost": "eq=saturation=2.0",
    "8. Desaturated": "eq=saturation=0.3", "9. Grayscale": "hue=s=0",
    "10. Sepia": "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131",
    "11. Vintage 1": "curves=vintage", "12. Vintage 2": "colorchannelmixer=.4:.4:.4:0:.2:.6:.2:0:.1:.1:.6",
    "13. Cinematic": "eq=contrast=1.3:saturation=1.2", "14. Warm Tone": "eq=temperature=0.5",
    "15. Cold Tone": "eq=temperature=-0.5", "16. Blur Soft": "gblur=sigma=2",
    "17. Blur Heavy": "gblur=sigma=10", "18. Sharpen": "unsharp=5:5:1.0",
    "19. Invert": "negate", "20. Mirror": "hflip", "21. VHS": "noise=alls=20",
    "22. Old Film": "curves=strong_contrast,noise=alls=10", "23. HDR Vivid": "eq=contrast=1.4:saturation=1.6",
    "24. Golden Hour": "eq=temperature=0.8:saturation=1.3", "25. Sunset": "colorchannelmixer=1.2:.1:.1",
    "26. Sunrise": "eq=temperature=0.7:brightness=0.2", "27. Ocean Blue": "colorbalance=bs=0.3",
    "28. Forest Green": "colorbalance=gs=0.3", "29. Rose Pink": "colorbalance=rs=0.3:bs=0.1",
    "30. Bollywood Vivid": "eq=saturation=1.8:contrast=1.2", "31. Bollywood Drama": "eq=contrast=1.4:saturation=0.8",
    "32. Lomo": "eq=contrast=1.3:saturation=1.4,vignette", "33. Vignette": "vignette=angle=PI/4",
    "34. Night Vision": "colorchannelmixer=.1:.5:.1:0:.1:.5:.1", "35. Thermal": "colormap=thermal",
    "36. Cartoon": "edgedetect=low=0.1:high=0.4", "37. Emboss": "edgedetect,negate",
    "38. Pencil Sketch": "edgedetect,negate,colorchannelmixer=.5:.5:.5", "39. Pixelate": "scale=iw/10:ih/10:flags=neighbor,scale=iw*10:ih*10:flags=neighbor",
    "40. Dreamy": "gblur=sigma=1.5,eq=brightness=0.1", "41. Soft Light": "eq=contrast=0.8:brightness=0.15",
    "42. Hard Light": "eq=contrast=1.8", "43. Cyberpunk": "eq=saturation=1.5:contrast=1.3",
    "44. Matrix Green": "colorchannelmixer=0:.5:0:0:.5:.8:.5:0:0:.5:0", "45. 8mm Film": "noise=alls=30",
    "46. Silver": "hue=s=0,eq=brightness=0.2", "47. Noir": "hue=s=0,eq=contrast=1.8",
    "48. Instagram Clarendon": "eq=contrast=1.2:saturation=1.35", "49. Instagram Gingham": "colorchannelmixer=.8:.8:.8",
    "50. Instagram Moon": "hue=s=0,eq=contrast=1.1", "51. Instagram Lark": "eq=brightness=0.1:saturation=1.2",
    "52. Cool Blue": "colorbalance=bs=0.4", "53. Warm Red": "colorbalance=rs=0.4",
    "54. Cross Process": "curves=cross_process", "55. Sin City": "hue=s=0,eq=contrast=1.5",
    "56. HDR Effect": "eq=contrast=1.3:brightness=0.1:saturation=1.3", "57. Super Saturated": "eq=saturation=3.0",
    "58. Fast Motion": "setpts=0.5*PTS", "59. Slow Motion": "setpts=2*PTS",
    "60. Edge Glow": "edgedetect=mode=colormix", "61. Comic": "edgedetect=mode=wires",
    "62. 60fps Smooth": "minterpolate=fps=60", "63. Rotate 90": "transpose=1",
    "64. Flip Vertical": "vflip", "65. Slow Blur": "tmix=frames=5",
    "66. Teal & Orange": "colorcorrect=rl=0.1:bl=-0.1", "67. AI Enhance": "scale=3840:2160:flags=lanczos,unsharp,eq=contrast=1.1",
    "68. AI 4K + HDR": "scale=3840:2160:flags=lanczos,eq=contrast=1.2:saturation=1.3",
    "69. AI Clear + Bright": "scale=3840:2160,unsharp,eq=brightness=0.1", "70. AI Bollywood": "scale=3840:2160,eq=saturation=1.8:contrast=1.2:temperature=0.2",
    "71. AI Cinematic 4K": "scale=3840:2160,eq=contrast=1.3:saturation=1.2,vignette", "72. AI Super HDR": "scale=3840:2160,eq=contrast=1.4:saturation=1.6:brightness=0.05",
  };

  Future<void> analyzeDemo() async {
    setState((){ isAnalyzing=true; analysis="AI Analyze करत आहे..."; });
    await Future.delayed(const Duration(seconds: 1));
    // Demo AI logic - इथे खरा व्हिडिओ असेल तर thumbnail वरून analyze होईल
    setState(() {
      suggested = ["30. Bollywood Vivid", "13. Cinematic", "23. HDR Vivid", "67. AI Enhance", "3. Bright +30", "24. Golden Hour"];
      analysis = "🔅 व्हिडिओ थोडा Dark आहे + Warm Tone आहे\n🎨 कलर चांगला आहे\n👇 या 6 Filters Best आहेत (72 पैकी):";
      isAnalyzing=false;
      selected=suggested.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("72 Filters + AI Suggest (${allFilters.length})")),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        ElevatedButton.icon(icon: const Icon(Icons.auto_awesome), label: const Text("व्हिडिओ टाका - AI Suggest करेल"), onPressed: analyzeDemo),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Text(analysis)),
        if(suggested.isNotEmpty)...[
          const SizedBox(height: 12),
          const Text("✨ AI Suggested (Best 6):", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          Wrap(spacing: 6, children: suggested.map((f) => ChoiceChip(label: Text(f), selected: selected==f, onSelected: (_)=>setState(()=>selected=f))).toList()),
          const SizedBox(height: 20),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: (){}, child: Text("Convert with $selected to 4K")),
          const Divider(height: 30),
          const Text("सर्व 72 Filters:", style: TextStyle(fontWeight: FontWeight.bold)),
          ...allFilters.keys.map((k) => ListTile(dense: true, title: Text(k), trailing: suggested.contains(k) ? const Icon(Icons.auto_awesome, color: Colors.yellow, size: 18) : null, selected: k==selected, onTap: ()=>setState(()=>selected=k))),
        ]
      ]),
    );
  }
}
