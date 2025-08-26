import 'package:bluebubbles/services/services.dart';

Future<void> main(List<String> args) async {
  final int messageCount =
      args.isNotEmpty ? int.tryParse(args[0]) ?? 100 : 100;
  final int concurrency =
      args.length > 1 ? int.tryParse(args[1]) ?? 1 : 1;

  await socket.runBenchmark(
    messageCount: messageCount,
    concurrency: concurrency,
  );
}
