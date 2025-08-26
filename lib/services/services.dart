/// Service entry point.
///
/// Previously this file blanket-exported every service in the application,
/// which made dependencies implicit and difficult to track.  The new approach
/// exposes only the [service locator](service_locator.dart) and requires modules
/// to import the exact services they rely on.
///
/// Import `service_locator.dart` and call [setupServices] during application
/// start-up.  Individual services should be imported from their respective
/// files rather than through a single aggregated export.
export 'service_locator.dart';
