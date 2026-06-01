# Worker Manager Workspace Tabs and Chat Test Design

## Goal

Make the macOS app easier to use by separating provider management, model management, and model conversation testing into three independent workspaces. Provider and model CRUD should feel intentional instead of mixed together, and model testing should become a real multi-turn chat test rather than a diff preview panel.

## Chosen Layout

Use three top-level tabs:

- `厂商管理`
- `模型管理`
- `对话测试`

This keeps the current native macOS style and preserves the existing feature module boundaries:

- `ProviderFeature` owns provider CRUD and provider connection testing.
- `ModelFeature` owns model CRUD and model discovery/sync.
- `ExecutionFeature` owns model chat testing.

## Provider Management

The provider workspace should focus only on providers.

- Left side: provider list with clear empty state.
- Top or right-side primary action: `新增厂商`.
- Detail area: selected provider information and edit form.
- Actions:
  - create provider
  - update selected provider
  - delete selected provider with confirmation
  - test selected provider connection

The add form and edit form may reuse fields, but the UI must clearly label whether the user is adding a provider or editing the selected provider. API key replacement remains optional when editing; leaving it blank keeps the existing key reference.

## Model Management

The model workspace should focus only on models.

- Provider picker at the top sets the active provider.
- Model list/table shows models for the active provider only.
- Actions:
  - sync models from provider
  - add custom model
  - delete model with confirmation

The custom model form should be visually separated from the list/sync actions. Empty states should explain whether the user needs to select a provider or add/sync models.

## Conversation Test

The test workspace should support simple multi-turn conversation testing.

- Model picker at the top.
- Conversation history area with user and assistant messages.
- Input composer with send and clear buttons.
- Sending state disables duplicate sends and shows progress.
- Errors appear in the shared status footer and do not erase the conversation.

The first implementation should not include raw response inspection, latency metrics, token counts, or advanced debugging controls. Those belong to a later debugging mode.

## Data Flow

- `ContentView` should compose the three tabs and shared app header/status.
- `AppState` remains the shared source of providers, models, selected provider, selected model, and status.
- `ProviderViewModel` continues to mutate provider data.
- `ModelViewModel` continues to mutate model data.
- `ExecutionViewModel` gains chat-specific state and a send action.
- Existing persistence and credential handling remain unchanged.

## Chat Behavior

- A chat message has a role (`user` or `assistant`) and text content.
- Sending requires a selected model and non-empty prompt.
- Sending appends the user message immediately.
- The service call should use the selected model/provider credentials.
- On success, append the assistant response.
- On failure, keep the user message and show an error status.
- `清空会话` clears only the chat history and draft input.

## Testing

Add focused tests for:

- `ContentView` or app composition indirectly through build coverage for the third tab.
- `ExecutionViewModel` chat behavior:
  - sending without a model fails validation
  - sending an empty prompt fails validation
  - a successful send appends user and assistant messages
  - clearing conversation removes history and draft input
- Existing provider/model tests should continue to pass.

Verify with:

- `swift test`
- `swift build`

## Non-Goals

- No redesign into a custom dark dashboard.
- No multi-window settings workflow.
- No raw HTTP response viewer.
- No latency/token/debug metrics in this pass.
- No changes to provider catalog semantics.
- No Keychain secret reveal UI.
