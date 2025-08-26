import 'dart:async';

import 'package:test/test.dart';

import 'package:bluebubbles/services/backend/queue/queue_impl.dart';
import 'package:bluebubbles/database/global/queue_items.dart';

class SimpleItem extends QueueItem {
  final String key;
  SimpleItem(this.key) : super(type: QueueType.sendMessage);

  @override
  String get queueKey => key;
}

class SimpleQueue extends Queue {
  final List<String> processed = [];

  @override
  Future<dynamic> prepItem(QueueItem _) async => _;

  @override
  Future<void> handleQueueItem(QueueItem item) async {
    if ((item as SimpleItem).key == 'fail') {
      throw Exception('boom');
    }
    processed.add(item.key);
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  test('items for same key are processed sequentially', () async {
    final q = SimpleQueue();
    final completers = List.generate(3, (_) => Completer<void>());

    q.queue(SimpleItem('a')..completer = completers[0]);
    q.queue(SimpleItem('a')..completer = completers[1]);
    q.queue(SimpleItem('a')..completer = completers[2]);

    await Future.wait(completers.map((c) => c.future));

    expect(q.processed, ['a', 'a', 'a']);
  });

  test('different keys run concurrently', () async {
    final q = SimpleQueue()..maxConcurrent = 2;

    final c1 = Completer<void>();
    final c2 = Completer<void>();

    q.queue(SimpleItem('a')..completer = c1);
    q.queue(SimpleItem('b')..completer = c2);

    final sw = Stopwatch()..start();
    await Future.wait([c1.future, c2.future]);
    sw.stop();

    // Since both items run in parallel the elapsed time should be roughly the
    // duration of a single item rather than the sum.
    expect(sw.elapsedMilliseconds < 180, isTrue);
  });

  test('failure in one key does not block others', () async {
    final q = SimpleQueue()..maxConcurrent = 2;

    final good = Completer<void>();
    final bad = Completer<void>();

    q.queue(SimpleItem('fail')..completer = bad);
    q.queue(SimpleItem('b')..completer = good);

    await good.future;
    expect(q.processed, contains('b'));
  });
}

