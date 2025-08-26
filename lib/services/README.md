# Service layer

This directory contains the application's service classes.  Each service is
responsible for a discrete area of the system (networking, UI helpers, etc.)
and should be imported individually by modules that require it.

A lightweight service locator based on `get_it` is provided via
`service_locator.dart`.  Call `setupServices()` during application start and
retrieve services with the top‑level getters (e.g. `ss` for `SettingsService`).

Avoid adding new blanket export files.  Instead, define explicit boundaries and
keep dependencies clear by importing only what is needed.
