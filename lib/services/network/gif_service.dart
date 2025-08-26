import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:bluebubbles/services/services.dart';

/// Simple result model representing a GIF.
class GifResult {
  GifResult({required this.url, required this.previewUrl});

  final String url;
  final String previewUrl;
}

/// Service to query the configured GIF API and return GIF URLs.
GifService gifService =
    Get.isRegistered<GifService>() ? Get.find<GifService>() : Get.put(GifService());

class GifService extends GetxService {
  final Dio _dio = Dio();

  /// Search the GIF API for a query and return a list of [GifResult].
  Future<List<GifResult>> search(String query, {int limit = 25}) async {
    if (ss.settings.gifApiKey.value.isEmpty) return [];
    try {
      final response = await _dio.get(
        'https://api.giphy.com/v1/gifs/search',
        queryParameters: {
          'api_key': ss.settings.gifApiKey.value,
          'q': query,
          'limit': limit,
          'rating': 'pg-13',
        },
      );
      final List data = response.data['data'];
      return data
          .map((e) => GifResult(
                url: e['images']['original']['url'],
                previewUrl: e['images']['fixed_height_small']['url'] ??
                    e['images']['original']['url'],
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
