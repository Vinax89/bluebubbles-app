import 'package:flutter/material.dart';

class ChatSearchPanel extends StatefulWidget {
  const ChatSearchPanel({
    super.key,
    this.onSenderChanged,
    this.onDateRangeChanged,
    this.onAttachmentChanged,
  });

  final ValueChanged<String>? onSenderChanged;
  final ValueChanged<DateTimeRange?>? onDateRangeChanged;
  final ValueChanged<String?>? onAttachmentChanged;

  @override
  ChatSearchPanelState createState() => ChatSearchPanelState();
}

class ChatSearchPanelState extends State<ChatSearchPanel> {
  final TextEditingController senderController = TextEditingController();
  DateTimeRange? range;
  String? attachmentType;

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: range,
    );
    setState(() => range = picked);
    if (widget.onDateRangeChanged != null) {
      widget.onDateRangeChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: senderController,
          decoration: const InputDecoration(
            labelText: 'Sender',
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: widget.onSenderChanged,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(range == null
                  ? 'No date range selected'
                  : '${range!.start.toLocal()} - ${range!.end.toLocal()}'),
            ),
            TextButton(
              onPressed: pickDateRange,
              child: const Text('Select Dates'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButton<String>(
          value: attachmentType,
          hint: const Text('Attachment Type'),
          items: const [
            DropdownMenuItem(value: 'image', child: Text('Images')),
            DropdownMenuItem(value: 'video', child: Text('Videos')),
            DropdownMenuItem(value: 'file', child: Text('Files')),
          ],
          onChanged: (val) {
            setState(() => attachmentType = val);
            if (widget.onAttachmentChanged != null) {
              widget.onAttachmentChanged!(val);
            }
          },
        ),
      ],
    );
  }
}
