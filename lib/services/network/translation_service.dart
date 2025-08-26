import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Global accessor for the [TranslationService]
TranslationService translationService =
    Get.isRegistered<TranslationService>() ? Get.find<TranslationService>() : Get.put(TranslationService());

/// A simple service that provides translation and language detection
/// using the LibreTranslate API. This class first detects the source
/// language and then translates the given text to a target language.
class TranslationService extends GetxService {
  late Dio _dio;

  /// Base URL for the LibreTranslate instance.
  /// This can be changed in the future to support different providers.
  final String baseUrl = 'https://libretranslate.com';

  @override
  void onInit() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    super.onInit();
  }

  /// Detect the language of [text]. Returns the detected language code
  /// (e.g. `en`, `es`). If detection fails, `en` is returned.
  Future<String> detect(String text) async {
    try {
      final response = await _dio.post(
        '$baseUrl/detect',
        data: {'q': text},
      );
      if (response.data is List && response.data.isNotEmpty) {
        return response.data[0]['language'] as String;
      }
    } catch (_) {}
    return 'en';
  }

  /// Translate [text] into the [target] language. This will first attempt
  /// to detect the language of the text. If the detected language is the
  /// same as the target language, the original [text] is returned.
  Future<String> translate(String text, String target) async {
    final source = await detect(text);
    if (source == target) return text;
    try {
      final response = await _dio.post(
        '$baseUrl/translate',
        data: {
          'q': text,
          'source': source,
          'target': target,
          'format': 'text',
        },
      );
      if (response.data is Map && response.data['translatedText'] is String) {
        return response.data['translatedText'] as String;
      }
    } catch (_) {}
    return text;
  }
}

