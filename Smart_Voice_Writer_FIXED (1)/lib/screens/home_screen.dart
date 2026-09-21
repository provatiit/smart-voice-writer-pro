
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "মাইকে চাপ দিয়ে বলা শুরু করুন...";
  String _result = "";
  bool _isProcessing = false;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    bool available = await _speech.initialize(
      onError: (e) => print('Error $e'),
    );
    if (available) {
      setState(() {
        _isListening = true;
        _text = "শুনছি...";
      });
      _speech.listen(
        localeId: "bn_BD",
        onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
          });
        },
      );
    }
  }

  void _stop() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _processWithAI() async {
    if (_text.isEmpty || _apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("API Key দিন এবং কিছু বলুন")));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final service = GeminiService(apiKey: _apiKeyController.text);
      final prompt = "নিচের অগোছালো বাংলা কথাকে সুন্দর, প্রফেশনাল বাংলায় ফরম্যাট করে দাও, বানান ঠিক করো:\n\n$_text";
      final res = await service.generateText(prompt);
      setState(() => _result = res);
    } catch (e) {
      setState(() => _result = "Error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Voice Writer PRO"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: "Gemini API Key", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
              child: Text(_text, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTapDown: (_) => _listen(),
              onTapUp: (_) => _stop(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 90, height: 90,
                decoration: BoxDecoration(color: _isListening ? Colors.red : const Color(0xFF00E5FF), shape: BoxShape.circle, boxShadow: [BoxShadow(color: (_isListening ? Colors.red : const Color(0xFF00E5FF)).withOpacity(0.4), blurRadius: _isListening ? 30 : 10)]),
                child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(_isListening ? "ছেড়ে দিন থামাতে" : "চেপে ধরে বলুন", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processWithAI,
                icon: _isProcessing ? const SizedBox(width:16,height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.auto_awesome),
                label: Text(_isProcessing ? "AI লিখছে..." : "AI দিয়ে সুন্দর করুন"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
            const SizedBox(height: 20),
            if (_result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00E5FF))),
                child: SelectableText(_result, style: const TextStyle(fontSize: 17, height: 1.5)),
              ),
          ],
        ),
      ),
    );
  }
}
