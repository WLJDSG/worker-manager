# Worker Manager UI Polish Design

## Goal

Improve the macOS app UI while preserving the existing provider, model discovery, connection test, persistence, and worker preview logic. The app should feel like a clean native macOS utility with clearer hierarchy, better empty/loading/error states, and practical management actions.

## Chosen Direction

Use the "native clean" direction:

- Keep the current `TabView` structure for provider and model work.
- Keep SwiftUI-native controls such as `GroupBox`, `List`, `Table`, `Picker`, `TextField`, `SecureField`, and `Button`.
- Improve spacing, alignment, section hierarchy, status presentation, and action grouping.
- Avoid a heavy dashboard redesign, custom dark sidebar, or large navigation rewrite.

## Scope

### Visual polish

- Add a calm top-level layout with consistent padding, section spacing, and min sizes.
- Make section headers more scannable with native labels and concise helper text.
- Improve provider list rows so the selected provider, provider name, and base URL are easier to scan.
- Give forms consistent label widths, control sizing, and primary/secondary action placement.
- Make the status footer more useful with neutral, success, and failure presentation.
- Keep colors semantic and system-adaptive for Light and Dark Mode.

### Basic experience completion

- Add empty states for:
  - no configured providers
  - no models for the selected provider
  - empty generated preview
- Add loading states for provider connection test and model fetching where existing async actions run.
- Improve validation messages for missing provider name, invalid Base URL, missing API key, and missing model name.
- Keep success and failure messages short, user-facing, and localized in Chinese.
- Disable actions when their prerequisites are missing.

### Management feature completion

- Add provider deletion.
  - Delete the selected provider.
  - Remove models belonging to the deleted provider.
  - Move selection to another remaining provider if possible.
  - Save the updated configuration.
  - Do not attempt to reveal or delete Keychain contents in this pass.
- Add provider editing.
  - Edit provider name, kind, Base URL, and optional replacement API key.
  - If the API key field is blank, keep the current key reference.
  - If a replacement key is entered, save it to the existing provider key reference.
  - Save updated provider configuration without changing provider identity.
- Add model deletion.
  - Delete a model from the selected provider.
  - If the deleted model was selected for worker preview, clear or move the selection safely.
  - Save the updated configuration.
- Add preview clearing.
  - Clear generated preview text without changing the instruction text.

## Architecture

The changes stay inside the existing app structure:

- `ContentView` remains the root SwiftUI view.
- `AppViewModel` remains the owner of provider/model state and async actions.
- Core services remain unchanged unless a small domain helper is required.

To keep `ContentView` readable, the implementation may introduce small private subviews or private helper views in the same file if needed. The change should not split files unless the implementation becomes difficult to read.

## Data Flow

- UI controls bind to existing `@Published` state where possible.
- New editing fields live in `AppViewModel` so they can be reset when selection changes and saved through existing persistence.
- Provider and model deletion call the existing private `save()` method after mutating in-memory arrays.
- Connection testing, model fetching, and worker preview continue to use existing services and methods.

## Error Handling

- Validation errors should be caught before mutating state.
- Async operation errors should continue to use `error.localizedDescription`.
- Destructive actions should use confirmation dialogs before deleting providers or models.
- Empty states should explain what is missing without showing technical details.

## Testing

Add focused tests for `AppViewModel` behavior if dependency injection can support it without large refactoring. At minimum verify with:

- `swift test`
- a macOS build command if available through SwiftPM
- manual UI pass for provider add/edit/delete, model fetch/delete, connection test, and preview clearing

## Non-Goals

- No redesign into a custom dashboard shell.
- No changes to worker execution request/response logic.
- No new provider catalog behavior.
- No Keychain migration or secret reveal UI.
- No multi-window, settings screen, or menu command work in this pass.
