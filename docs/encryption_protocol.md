# Encrypted Payloads

BlueBubbles clients now encrypt socket payloads on a per-chat basis. Each client generates an elliptic curve key pair and performs an ECDH key exchange to derive a shared secret for the chat.

Outgoing socket messages include the following fields:

- `chatGuid`: identifies the conversation whose key should be used.
- `data`: base64 AES-GCM encrypted JSON payload.
- `encrypted`: `true` when the payload is encrypted.

Servers should decrypt incoming data using the current session key for the provided chat and re‑encrypt responses using the same key. Session keys are rotated whenever a new conversation is created or when group participants change.
