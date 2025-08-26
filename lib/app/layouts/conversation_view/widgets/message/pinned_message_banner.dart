import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PinnedMessageBanner extends StatelessWidget {
  final Message message;
  const PinnedMessageBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: context.theme.colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(
            ss.settings.skin.value == Skins.iOS ? CupertinoIcons.pin : Icons.push_pin_outlined,
            size: 16,
            color: context.theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.fullText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.textTheme.bodyMedium!
                  .copyWith(color: context.theme.colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
