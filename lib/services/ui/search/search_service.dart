import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:get/get.dart';

SearchService ss = Get.isRegistered<SearchService>() ? Get.find<SearchService>() : Get.put(SearchService());

class SearchService extends GetxService {
  Future<List<Message>> search({
    String? sender,
    DateTime? start,
    DateTime? end,
    String? attachmentType,
  }) async {
    List<Message> messages = Database.messages.getAll();

    return messages.where((m) {
      if (sender != null && sender.isNotEmpty) {
        final address = m.handle?.address ?? m.handle?.originalAddress;
        if (address == null || !address.contains(sender)) {
          return false;
        }
      }
      if (start != null && (m.dateCreated == null || m.dateCreated!.isBefore(start))) {
        return false;
      }
      if (end != null && (m.dateCreated == null || m.dateCreated!.isAfter(end))) {
        return false;
      }
      if (attachmentType != null && attachmentType.isNotEmpty) {
        final hasType = m.dbAttachments.any((a) => a.mimeType?.contains(attachmentType) ?? false);
        if (!hasType) return false;
      }
      return true;
    }).toList();
  }
}
