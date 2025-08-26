import 'dart:async';

import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:get/get.dart';

abstract class Queue extends GetxService {
  bool isProcessing = false;
  List<QueueItem> items = [];

  /// Tracks chats that currently have an active send. This ensures ordering
  /// is preserved per chat even when multiple items are processed in
  /// parallel.
  /// Active queue keys currently being processed. Keys allow higher level
  /// implementations to define ordering groups (for example per chat or per
  /// attachment batch).
  final Set<String> _activeKeys = <String>{};

  /// Number of items currently being processed.
  int _processing = 0;

  /// Maximum number of concurrent [handleQueueItem] calls. This can be tuned
  /// based on performance characteristics of the target platform.
  int maxConcurrent = 3;

  Future<void> queue(QueueItem item) async {
    final returned = await prepItem(item);
    // we may get a link split into 2 messages
    if (item is OutgoingItem && returned is List) {
      items.addAll(returned.map((e) => OutgoingItem(
        type: item.type,
        chat: item.chat,
        message: e,
        completer: item.completer,
        selected: item.selected,
        reaction: item.reaction,
      )));
    } else {
      items.add(item);
    }
    if (!isProcessing || (items.isEmpty && item is IncomingItem)) processNextItem();
  }

  Future<dynamic> prepItem(QueueItem _);

  Future<void> processNextItem() async {
    // If there are no more queued items and nothing is being processed, stop
    // the processing loop.
    if (items.isEmpty && _processing == 0) {
      isProcessing = false;
      return;
    }

    isProcessing = true;

    // Fill available concurrency slots with queued items that are not blocked
    // by an active chat.
    while (_processing < maxConcurrent) {
      // Find the first item whose chat is not currently processing.
      final index = items.indexWhere((item) => !_activeKeys.contains(item.queueKey));

      if (index == -1) break;

      final queued = items.removeAt(index);
      _activeKeys.add(queued.queueKey);

      _processing++;
      _processItem(queued);
    }
  }

  Future<void> _processItem(QueueItem queued) async {
    try {
      await handleQueueItem(queued).catchError((err) async {
        if (queued is OutgoingItem && ss.settings.cancelQueuedMessages.value) {
          final toCancel = List<OutgoingItem>.from(
            items.whereType<OutgoingItem>().where((e) => e.chat.guid == queued.chat.guid),
          );
          for (OutgoingItem i in toCancel) {
            items.remove(i);
            final m = i.message;
            final tempGuid = m.guid;
            m.guid = m.guid!.replaceAll("temp", "error-Canceled due to previous failure");
            m.error = MessageError.BAD_REQUEST.code;
            Message.replaceMessage(tempGuid, m);
          }
        }
      });
      queued.completer?.complete();
    } catch (ex, stacktrace) {
      Logger.error("Failed to handle queued item!", error: ex, trace: stacktrace);
      queued.completer?.completeError(ex);
    } finally {
      _activeKeys.remove(queued.queueKey);
      _processing--;
      // Trigger processing of additional items if available.
      await processNextItem();
    }
  }

  Future<void> handleQueueItem(QueueItem _);
}