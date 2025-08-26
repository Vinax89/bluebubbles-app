import 'package:get_it/get_it.dart';

import 'backend/action_handler.dart';
import 'backend/filesystem/filesystem_service.dart';
import 'backend/lifecycle/lifecycle_service.dart';
import 'backend/notifications/notifications_service.dart';
import 'backend/java_dart_interop/intents_service.dart';
import 'backend/java_dart_interop/method_channel_service.dart';
import 'backend/queue/incoming_queue.dart';
import 'backend/queue/outgoing_queue.dart';
import 'backend/settings/settings_service.dart';
import 'backend/setup/setup_service.dart';
import 'backend/sync/sync_service.dart';
import 'backend/sync/session_registry.dart';
import 'backend_ui_interop/event_dispatcher.dart';
import 'custom_service.dart';
import 'network/downloads_service.dart';
import 'network/firebase/cloud_messaging_service.dart';
import 'network/firebase/firebase_database_service.dart';
import 'network/http_service.dart';
import 'network/socket_service.dart';
import 'network/translation_service.dart';
import 'ui/attachments_service.dart';
import 'ui/contact_service.dart';
import 'ui/chat/chat_manager.dart';
import 'ui/chat/chats_service.dart';
import 'ui/chat/global_chat_service.dart' as gcs;
import 'ui/navigator/navigator_service.dart';
import 'ui/theme/themes_service.dart';

/// Central service locator for the application.
///
/// Services should be registered here and retrieved via [locator].
final GetIt locator = GetIt.instance;

/// Registers the core services used throughout the application.
///
/// This creates the service instances lazily, allowing tests to override
/// registrations and helping keep boundaries explicit.
void setupServices() {
  void register<T extends Object>(T Function() create) {
    if (!locator.isRegistered<T>()) {
      locator.registerLazySingleton<T>(create);
    }
  }

  register<SettingsService>(() => SettingsService());
  register<NavigatorService>(() => NavigatorService());
  register<ChatManager>(() => ChatManager());
  register<ThemesService>(() => ThemesService());
  register<FilesystemService>(() => FilesystemService());
  register<NotificationsService>(() => NotificationsService());
  register<LifecycleService>(() => LifecycleService());
  register<ActionHandler>(() => ActionHandler());
  register<IntentsService>(() => IntentsService());
  register<MethodChannelService>(() => MethodChannelService());
  register<IncomingQueue>(() => IncomingQueue());
  register<OutgoingQueue>(() => OutgoingQueue());
  register<SetupService>(() => SetupService());
  register<SyncService>(() => SyncService());
  register<SessionRegistry>(() => SessionRegistry());
  register<EventDispatcher>(() => EventDispatcher());
  register<CloudMessagingService>(() => CloudMessagingService());
  register<FirebaseDatabaseService>(() => FirebaseDatabaseService());
  register<AttachmentDownloadService>(() => AttachmentDownloadService());
  register<HttpService>(() => HttpService());
  register<SocketService>(() => SocketService());
  register<TranslationService>(() => TranslationService());
  register<AttachmentsService>(() => AttachmentsService());
  register<ContactsService>(() => ContactsService());
  register<CustomService>(() => CustomService());
  register<ChatsService>(() => ChatsService());
}

SettingsService get ss => locator<SettingsService>();
NavigatorService get ns => locator<NavigatorService>();
ChatManager get cm => locator<ChatManager>();
ThemesService get ts => locator<ThemesService>();
FilesystemService get fs => locator<FilesystemService>();
NotificationsService get notif => locator<NotificationsService>();
LifecycleService get ls => locator<LifecycleService>();
ActionHandler get ah => locator<ActionHandler>();
IntentsService get intents => locator<IntentsService>();
MethodChannelService get mcs => locator<MethodChannelService>();
IncomingQueue get inq => locator<IncomingQueue>();
OutgoingQueue get outq => locator<OutgoingQueue>();
SetupService get setup => locator<SetupService>();
SyncService get sync => locator<SyncService>();
EventDispatcher get eventDispatcher => locator<EventDispatcher>();
CloudMessagingService get fcm => locator<CloudMessagingService>();
FirebaseDatabaseService get fdb => locator<FirebaseDatabaseService>();
AttachmentDownloadService get attachmentDownloader => locator<AttachmentDownloadService>();
HttpService get http => locator<HttpService>();
SocketService get socket => locator<SocketService>();
TranslationService get translationService => locator<TranslationService>();
AttachmentsService get as => locator<AttachmentsService>();
ContactsService get cs => locator<ContactsService>();
CustomService get customService => locator<CustomService>();
ChatsService get chats => locator<ChatsService>();
SessionRegistry get sessionRegistry => locator<SessionRegistry>();
dynamic get GlobalChatService => gcs.GlobalChatService;
