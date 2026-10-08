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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const FilterScreen(),
    );
  }
}

class FilterInfo {
  final String name;
  final List<double> matrix;
  final String ffmpeg;
  final Color color;
  FilterInfo({required this.name, required this.matrix, required this.ffmpeg, required this.color});
}

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});
  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  XFile? videoFile;
  VideoPlayerController? controller;
  int selectedIndex = 0;
  bool isConverting = false;

  List<double> identity() => [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0];
  List<double> brightness(double b) => [1,0,0,0,b*255, 0,1,0,0,b*255, 0,0,1,0,b*255, 0,0,0,1,0];
  List<double> contrast(double c) { double t=(1-c)*128; return [c,0,0,0,t, 0,c,0,0,t, 0,0,c,0,t, 0,0,0,1,0]; }

  late List<FilterInfo> filters;

  @override
  void initState() {
    super.initState();
    filters = [];
    filters.add(FilterInfo(name: "1. Original", matrix: identity(), ffmpeg: "null", color: Colors.grey.shade300));
    filters.add(FilterInfo(name: "2. 4K Upscale", matrix: contrast(1.15), ffmpeg: "scale=3840:2160:flags=lanczos", color: Colors.blueGrey));
    filters.add(FilterInfo(name: "3. Bright +50", matrix: brightness(0.2), ffmpeg: "eq=brightness=0.1", color: Colors.yellow.shade200));
    filters.add(FilterInfo(name: "4. Dark -30", matrix: brightness(-0.12), ffmpeg: "eq=brightness=-0.15", color: Colors.brown.shade400));
    filters.add(FilterInfo(name: "5. High Contrast", matrix: contrast(1.5), ffmpeg: "eq=contrast=1.5", color: Colors.black87));
    filters.add(FilterInfo(name: "6. Low Contrast", matrix: contrast(0.7), ffmpeg: "eq=contrast=0.7", color: Colors.grey.shade500));
    filters.add(FilterInfo(name: "7. Saturation Boost", matrix: [1.3,0,0,0,-20, 0,1.3,0,0,-20, 0,0,1.3,0,-20, 0,0,0,1,0], ffmpeg: "eq=saturation=1.8", color: Colors.pink));
    filters.add(FilterInfo(name: "8. Desaturated", matrix: [0.6,0.2,0.2,0,0, 0.2,0.6,0.2,0,0, 0.2,0.2,0.6,0,0, 0,0,0,1,0], ffmpeg: "eq=saturation=0.3", color: Colors.grey));
    filters.add(FilterInfo(name: "9. Grayscale", matrix: [0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0.2126,0.7152,0.0722,0,0, 0,0,0,1,0], ffmpeg: "hue=s=0", color: Colors.black26));
    filters.add(FilterInfo(name: "10. Sepia", matrix: [0.393,0.769,0.189,0,0, 0.349,0.686,0.168,0,0, 0.272,0.534,0.131,0,0, 0,0,0,1,0], ffmpeg: "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131", color: const Color(0xFF704214)));
    filters.add(FilterInfo(name: "11. Vintage 1", matrix: [1.1,0,0,0,10, 0,1.0,0,0,5, 0,0,0.9,0,0, 0,0,0,1,0], ffmpeg: "curves=vintage", color: Colors.orange.shade300));
    filters.add(FilterInfo(name: "12. Vintage 2", matrix: [0.9,0.1,0,0,15, 0.1,0.9,0,0,10, 0,0,0.8,0,0, 0,0,0,1,0], ffmpeg: "eq=brightness=0.05:saturation=0.8", color: Colors.orange.shade700));
    filters.add(FilterInfo(name: "13. Cinematic", matrix: contrast(1.3), ffmpeg: "eq=contrast=1.3:brightness=0.05:saturation=1.2", color: Colors.indigo));
    filters.add(FilterInfo(name: "14. Warm Tone", matrix: [1.2,0,0,0,20, 0,1.05,0,0,10, 0,0,0.9,0,-10, 0,0,0,1,0], ffmpeg: "eq=brightness=0.06:saturation=1.2", color: Colors.deepOrange.shade200));
    filters.add(FilterInfo(name: "15. Cold Tone", matrix: [1,0,0,0,-15, 0,1,0,0,-5, 0,0,1.2,0,20, 0,0,0,1,0], ffmpeg: "eq=brightness=0.02:saturation=1.1", color: Colors.lightBlue.shade200));

    List<String> extraNames = [
      "16. Cool Blue","17. Sunset Glow","18. Forest Green","19. Night Mode","20. Dreamy",
      "21. Lomo","22. Hollywood","23. Retro 70s","24. Faded Film","25. HDR Boost",
      "26. Vivid Pop","27. Soft Light","28. Sharp Pro","29. Moody Dark","30. Teal Orange",
      "31. Cross Process","32. BW High","33. BW Low","34. Neon Glow","35. Pastel",
      "36. Vibrant Plus","37. Matte Finish","38. Deep Tone","39. Light Leak","40. Golden Hour",
      "41. Silver Shine","42. Bronze","43. Rose Gold","44. Aqua Blue","45. Lavender",
      "46. Emerald","47. Ruby Red","48. Sahara","49. Arctic Cold","50. Tropical",
      "51. Urban Street","52. Portrait Pro","53. Landscape Pro","54. Studio Light","55. Film 1",
      "56. Film 2","57. Film 3","58. Kodak Gold","59. Fuji Color","60. Polaroid",
      "61. Insta Filter","62. Snap Style","63. YT Pop","64. AI Enhance","65. AI 4K Plus Pro",
      "66. AI Bright Fix","67. AI Dark Fix","68. AI Color Pop","69. AI Night Clear","70. AI Skin Smooth",
      "71. AI Ultra Clear","72. AI 4K Plus FINAL"
    ];

    for (int i = 0; i < extraNames.length; i++) {
      double c = 0.8 + (i % 6) * 0.12;
      double b = ((i % 7) - 3) * 0.04;
      List<double> m = (i % 2 == 0)? contrast(c) : brightness(b);
      if (i == extraNames.length - 1) {
        m = [1.4,0,0,0,-10, 0,1.4,0,0,-10, 0,0,1.4,0,-10, 0,0,0,1,0];
      }
      String ff = i == extraNames.length - 1
        ? "scale=3840:2160:flags=lanczos,eq=contrast=1.4:saturation=1.4:brightness=0.06,unsharp=5:5:1.0:5:5:0.0"
          : "eq=contrast=${c.toStringAsFixed(2)}:brightness=${b.toStringAsFixed(2)}:saturation=1.3";
      filters.add(FilterInfo(
        name: extraNames[i],
        matrix: m,
        ffmpeg: ff,
        color: Colors.primaries[i % Colors.primaries.length].shade300,
      ));
    }
  }

  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    videoFile = file;
    controller?.dispose();
    controller = VideoPlayerController.file(File(file.path));
    await controller!.initialize();
    controller!.setLooping(true);
    controller!.play();
    setState(() {});
  }

  Future<void> convertVideo() async {
    if (videoFile == null) return;
    setState(() => isConverting = true);
    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final inPath = videoFile!.path;
    final filter = filters[selectedIndex].ffmpeg;
    String cmd;
    if (filter == "null") {
      cmd = "-i $inPath -c:v libx264 -preset ultrafast -crf 23 -c:a copy $outPath";
    } else {
      cmd = "-i $inPath -vf $filter -c:v libx264 -preset ultrafast -crf 23 -c:a aac $outPath";
    }
    await FFmpegKit.execute(cmd).then((session) async {
      final rc = await session.getReturnCode();
      if (mounted) {
        if (ReturnCode.isSuccess(rc)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $outPath')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Convert Failed')));
        }
      }
    });
    setState(() => isConverting = false);
  }

  @override
  void dispose() { controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final current = filters[selectedIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('${filters.length} Filters', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(onPressed: pickVideo, icon: const Icon(Icons.video_library, size: 18), label: const Text('व्हिडिओ टाका', style: TextStyle(fontSize: 12))),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 260, width: double.infinity, color: Colors.black,
            child: controller!= null && controller!.value.isInitialized
              ? ColorFiltered(colorFilter: ColorFilter.matrix(current.matrix), child: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!)))
                : const Center(child: Text('व्हिडिओ निवडा', style: TextStyle(color: Colors.white))),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
                Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('15. Cold Tone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text('Warm आहे - Cold करा', style: TextStyle(fontSize: 10))]))),
                const SizedBox(width: 8),
                Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('72. AI 4K Plus FINAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text('Final Export Best', style: TextStyle(fontSize: 10))]))),
              ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed: isConverting? null : convertVideo, child: isConverting? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('CONVERT - ${current.name}', style: const TextStyle(fontWeight: FontWeight.bold)))),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text('सर्व ${filters.length} फिल्टर (आडवा स्लाइड करा 👉):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
          SizedBox(
            height: 115,
            child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: filters.length, itemBuilder: (context, index) {
                bool isSel = index == selectedIndex; final f = filters[index];
                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 82, margin: const EdgeInsets.only(right: 10, bottom: 8, top: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSel? Colors.green : Colors.grey.shade300, width: isSel? 2.5 : 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isSel? 0.25 : 0.12), blurRadius: isSel? 8 : 4, offset: Offset(0, isSel? 4 : 2))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(height: 48, width: 58, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: f.color), child: ColorFiltered(colorFilter: ColorFilter.matrix(f.matrix), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(colors: [f.color, f.color.withOpacity(0.6)])), child: const Icon(Icons.image, size: 22, color: Colors.white70)))),
                        const SizedBox(height: 6),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(f.name, maxLines: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: isSel? FontWeight.bold : FontWeight.w500))),
                        if (isSel) Container(margin: const EdgeInsets.only(top: 3), height: 4, width: 18, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10))),
                      ])),
                );
              }),
          ),
        ],
      ),
    );
  }
}
