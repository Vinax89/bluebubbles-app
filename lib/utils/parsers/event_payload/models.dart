import 'package:meta/meta.dart';

@immutable
class AttachmentPayload {
  final String guid;
  final String? uti;
  final String? mimeType;
  final bool? isOutgoing;
  final String? transferName;
  final int? totalBytes;
  final int? height;
  final int? width;

  const AttachmentPayload({
    required this.guid,
    this.uti,
    this.mimeType,
    this.isOutgoing,
    this.transferName,
    this.totalBytes,
    this.height,
    this.width,
  });

  factory AttachmentPayload.fromJson(Map<String, dynamic> json) {
    return AttachmentPayload(
      guid: json['guid'] as String,
      uti: json['uti'] as String?,
      mimeType: json['mimeType'] as String?,
      isOutgoing: json['isOutgoing'] as bool?,
      transferName: json['transferName'] as String?,
      totalBytes: json['totalBytes'] is int ? json['totalBytes'] as int : null,
      height: json['height'] is int ? json['height'] as int : null,
      width: json['width'] is int ? json['width'] as int : null,
    );
  }
}

@immutable
class ChatPayload {
  final String guid;
  final String? chatIdentifier;
  final String? service;
  final List<String>? participants;

  const ChatPayload({
    required this.guid,
    this.chatIdentifier,
    this.service,
    this.participants,
  });

  factory ChatPayload.fromJson(Map<String, dynamic> json) {
    return ChatPayload(
      guid: json['guid'] as String,
      chatIdentifier: json['chatIdentifier'] as String?,
      service: json['service'] as String?,
      participants: (json['participants'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

@immutable
class HandlePayload {
  final String address;
  final String? service;

  const HandlePayload({
    required this.address,
    this.service,
  });

  factory HandlePayload.fromJson(Map<String, dynamic> json) {
    return HandlePayload(
      address: json['address'] as String,
      service: json['service'] as String?,
    );
  }
}
