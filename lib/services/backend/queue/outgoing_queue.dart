import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/services/backend/queue/queue_impl.dart';
import 'package:get/get.dart';

OutgoingQueue outq = Get.isRegistered<OutgoingQueue>() ? Get.find<OutgoingQueue>() : Get.put(OutgoingQueue());

class OutgoingQueue extends Queue {

  @override
  Future<dynamic> prepItem(QueueItem _) async {
    assert(_ is OutgoingItem);
    final item = _ as OutgoingItem;

    switch (item.type) {
      case QueueType.sendMultipart:
      case QueueType.sendMessage:
        return await ah.prepMessage(item.chat, item.message, item.selected, item.reaction, clearNotificationsIfFromMe: !(item.customArgs?['notifReply'] ?? false));
      case QueueType.sendAttachment:
        return await ah.prepAttachment(item.chat, item.message, isAudioMessage: item.customArgs?['audio'] ?? false);
      case QueueType.sendSticker:
        return await ah.prepSticker(item.chat, item.message);
      default:
        Logger.info("Unhandled queue event: ${item.type.name}");
        break;
    }
  }

  Future<T> handleSend<T>(Future<T> Function() process, Chat chat) async {
    Timer? progressTimer = Timer(const Duration(seconds: 5), () {
      chat.sendProgress.value = .9;
    });

    try {
      final result = await process();
      progressTimer.cancel();
      if (chat.sendProgress.value != 0) {
        chat.sendProgress.value = 1;
        await Future.delayed(const Duration(milliseconds: 500));
        chat.sendProgress.value = 0;
      }
      return result;
    } catch (e) {
      progressTimer.cancel();
      if (chat.sendProgress.value != 0) {
        chat.sendProgress.value = 1;
        await Future.delayed(const Duration(milliseconds: 500));
        chat.sendProgress.value = 0;
      }
      rethrow;
    } finally {
      progressTimer.cancel();
    }
  }

  @override
  Future<void> handleQueueItem(QueueItem _) async {
    assert(_ is OutgoingItem);
    final item = _ as OutgoingItem;

    switch (item.type) {
      case QueueType.sendMessage:
        await handleSend(() => ah.sendMessage(item.chat, item.message, item.selected, item.reaction), item.chat);
        break;
      case QueueType.sendMultipart:
        await handleSend(() => ah.sendMultipart(item.chat, item.message, item.selected, item.reaction), item.chat);
        break;
      case QueueType.sendAttachment:
        await handleSend(() => ah.sendAttachment(item.chat, item.message, item.customArgs?['audio'] ?? false), item.chat);
        break;
      case QueueType.sendSticker:
        await handleSend(() => ah.sendSticker(item.chat, item.message), item.chat);
        break;
      default:
        Logger.info("Unhandled queue event: ${item.type.name}");
        break;
    }
  }
}