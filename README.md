# Worker Manager

Worker Manager is a macOS app and CLI bridge for configuring model providers and worker models. Codex can use the CLI bridge to delegate implementation tasks to configured models while GPT keeps planning, review, and final file-write decisions.

## Build and Test

```bash
swift build
swift test
```

## Run the App

```bash
swift run WorkerManagerApp
```

## Configure DeepSeek

1. Open the app.
2. Add provider:
   - Provider name: `DeepSeek`
   - Kind: `deepSeek`
   - Base URL: `https://api.deepseek.com`
   - API key: your DeepSeek API key
3. Click `Fetch Models`.
4. Add custom model:
   - Model name: `deepseek-v4-pro`
   - Display name: `DeepSeek V4 Pro`

## Codex Delegation Flow

GPT remains responsible for planning, code review, and final write decisions. Worker Manager only supplies the configured execution model.

```bash
cat > /tmp/worker-task.md <<'TASK'
Implement the requested feature and return a unified diff only.
TASK
```

```bash
swift run worker-manager-cli run \
  --model deepseek-v4-pro \
  --task-file /tmp/worker-task.md \
  --workspace /path/to/target/project
```

Codex should review the returned diff before applying it.

## Config Location

Provider and model metadata is stored at:

```text
~/.worker-manager/config.json
```

API keys are stored in macOS Keychain under service:

```text
com.worker-manager.credentials
```
