import 'package:bluebubbles/database/models.dart' hide Entity;
import 'package:emojis/emojis.dart';
import 'package:flutter/foundation.dart';

enum ReactionType { love, like, dislike, laugh, emphasize, question }

class ReactionTypes {
  static List<ReactionType> toList() {
    return ReactionType.values;
  }

  static ReactionType? fromString(String? type) {
    if (type == null) return null;
    try {
      return ReactionType.values.firstWhere((e) => e.name == type);
    } catch (_) {
      return null;
    }
  }

  static final Map<ReactionType, String> reactionToVerb = {
    ReactionType.love: "loved",
    ReactionType.like: "liked",
    ReactionType.dislike: "disliked",
    ReactionType.laugh: "laughed at",
    ReactionType.emphasize: "emphasized",
    ReactionType.question: "questioned",
  };

  static final Map<ReactionType, String> negativeReactionToVerb = {
    ReactionType.love: "removed a heart from",
    ReactionType.like: "removed a like from",
    ReactionType.dislike: "removed a dislike from",
    ReactionType.laugh: "removed a laugh from",
    ReactionType.emphasize: "removed an exclamation from",
    ReactionType.question: "removed a question mark from",
  };

  static final Map<ReactionType, String> reactionToEmoji = {
    ReactionType.love: Emojis.redHeart,
    ReactionType.like: Emojis.thumbsUp,
    ReactionType.dislike: Emojis.thumbsDown,
    ReactionType.laugh: Emojis.faceWithTearsOfJoy,
    ReactionType.emphasize: Emojis.redExclamationMark,
    ReactionType.question: Emojis.redQuestionMark,
  };

  static final Map<String, ReactionType> emojiToReaction =
      reactionToEmoji.map((key, value) => MapEntry(value, key));

  static String? getVerb(String reaction) {
    final negative = reaction.startsWith('-');
    final type = fromString(reaction.replaceFirst('-', ''));
    if (type == null) return null;
    return negative ? negativeReactionToVerb[type] : reactionToVerb[type];
  }
}

List<Message> getUniqueReactionMessages(List<Message> messages) {
  List<int> handleCache = [];
  List<Message> output = [];
  // Sort the messages, putting the latest at the top
  final ids = messages.map((e) => e.guid).toSet();
  messages.retainWhere((element) => ids.remove(element.guid));
  messages.sort(Message.sort);
  // Iterate over the messages and insert the latest reaction for each user
  for (Message msg in messages) {
    int cache = msg.isFromMe! ? 0 : msg.handleId ?? 0;
    if (!handleCache.contains(cache) && !kIsWeb) {
      handleCache.add(cache);
      // Only add the reaction if it's not a "negative"
      if (!msg.associatedMessageType!.startsWith("-")) {
        output.add(msg);
      }
    } else if (kIsWeb && !msg.associatedMessageType!.startsWith("-")) {
      output.add(msg);
    }
  }

  return output;
}