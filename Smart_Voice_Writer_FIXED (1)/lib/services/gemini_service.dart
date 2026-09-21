
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  GeminiService({required this.apiKey});

  Future<String> generateText(String prompt) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? "কিছু পাওয়া যায়নি";
  }
}
