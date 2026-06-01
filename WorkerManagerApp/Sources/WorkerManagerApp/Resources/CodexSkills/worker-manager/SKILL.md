---
name: worker-manager
description: Use when working on the Worker Manager macOS app or CLI, especially when GPT/Codex should create specs and plans, delegate implementation to a worker model, apply generated code safely, run SwiftPM verification, package the macOS app, or maintain the bundled Codex skill.
---

# Worker Manager Project Skill

Use this skill for development, implementation delegation, testing, worker orchestration, and packaging work in the Worker Manager repository.

## Project Summary

Worker Manager is a SwiftPM macOS SwiftUI app plus CLI for managing AI model providers, model lists, and worker-model execution. The app is organized into feature packages:

- `Core`: domain types, provider store, keychain store, HTTP client, shared app state, status kind.
- `ProviderFeature`: provider CRUD and provider connection testing.
- `ModelFeature`: model discovery/sync and custom model CRUD.
- `ExecutionFeature`: worker execution and multi-turn model conversation testing.
- `SharedUI`: reusable empty-state and status-footer UI.
- `WorkerManagerApp`: macOS app composition.
- `WorkerManagerCLI`: CLI entrypoint for worker delegation.

## Current UX Direction

The app should keep a native macOS utility style:

- Top-level tabs are `厂商管理`, `模型管理`, and `对话测试`.
- Provider CRUD belongs in `ProviderFeature`.
- Model CRUD belongs in `ModelFeature`.
- Model conversation testing belongs in `ExecutionFeature`.
- Keep provider/model management separate from chat testing.
- Prefer SwiftUI-native controls, semantic colors, confirmation dialogs, and clear empty/loading/error states.

## GPT-Led Worker Coding Workflow

Use this workflow for non-trivial feature work, refactors, UI changes, or behavior changes.

1. **GPT/Codex explores the codebase first.**
   - Prefer CodeGraph for structural questions.
   - Read only the files needed to understand the target modules.
   - Check `git status --short` before editing.

2. **GPT/Codex writes the specification.**
   - Clarify the product intent and constraints.
   - Write a concise spec under `docs/superpowers/specs/`.
   - The spec should define scope, non-goals, data flow, UX behavior, error handling, and verification.

3. **GPT/Codex writes the implementation plan.**
   - Save the plan under `docs/superpowers/plans/`.
   - Use small, testable tasks.
   - Include exact files, test commands, and expected failures/passes.

4. **GPT/Codex delegates implementation to the worker.**
   - The worker's primary job is to generate code changes from the approved spec and plan.
   - The worker receives the implementation request, spec path, plan path, current file paths, strict API constraints, and expected test commands.
   - Ask the worker to implement the planned changes and return a unified diff only.
   - The worker must not invent modules, APIs, paths, or old code structures.

5. **GPT/Codex applies the generated implementation safely.**
   - Treat the worker diff as an implementation draft, not as final truth.
   - Codex is responsible for checking scope, API compatibility, package structure, tests, and user intent before applying changes.
   - Apply the correct generated code, adjust it when needed, and discard any unrelated or unsafe portions.

6. **GPT/Codex verifies and finishes the final result.**
   - Run focused tests first.
   - Run full `swift test`, `swift build`, and `git diff --check`.
   - Report exact verification commands and outcomes.

## External Worker Access Policy

For this repository, the user has explicitly approved sending necessary local workspace context, source files, task descriptions, specs, and plans to the configured external worker model so it can draft code.

Default behavior for this project:

- Do not stop to ask for external worker file-read consent again for ordinary Worker Manager implementation tasks.
- Include enough file context for the worker to follow the current repository structure.
- Still keep secrets out of worker prompts. Do not send API keys, tokens, private credentials, or unrelated personal files.
- If platform or sandbox policy blocks external disclosure, respect the block and continue with local implementation. Do not attempt to bypass policy.

## Worker Code Generation Rule

When using the configured worker model, call the worker to generate the planned code changes. Codex keeps ownership of planning, integration, verification, and final quality.

1. State the active worker model and workspace.
2. Write a task file under `/private/tmp`.
3. The task file should include:
   - workspace path
   - spec path
   - plan path
   - exact target files
   - current module names
   - APIs that must not be invented
   - test commands that must pass
   - instruction: implement the requested code changes
   - instruction: `Return unified diff only.`
4. Run:

```bash
swift run worker-manager-cli run \
  --model deepseek-v4-pro \
  --task-file <task-file> \
  --workspace /Users/wenlanjun/办公/workspace/worker-manager
```

5. Inspect the returned diff for correctness, scope, invented APIs, and compatibility with the current SwiftPM package structure.
6. Apply the useful generated implementation, editing it as needed to fit the project.
7. Run the focused tests, then full tests/build.

Reject worker diffs that invent old or nonexistent APIs such as `CoreFeature`, `Provider`, `Model`, no-argument feature views, `SplitView`, or missing dependency injection.

## Strict Worker Prompt Template

Use this shape for worker task files:

```text
Workspace: /Users/wenlanjun/办公/workspace/worker-manager

Task:
<one clear implementation request>

Worker role:
Generate the code changes for this task from the spec and plan. Do not perform a code review. Do not write commentary.

Spec:
<path to docs/superpowers/specs/...md>

Plan:
<path to docs/superpowers/plans/...md>

Current modules:
- Core
- ProviderFeature
- ModelFeature
- ExecutionFeature
- SharedUI
- WorkerManagerApp
- WorkerManagerCLI

Target files:
- <exact file paths>

Rules:
- Implement the requested code changes.
- Return unified diff only. No explanation and no review report.
- Use the current repository structure exactly.
- Do not invent modules, types, functions, initializers, or old APIs.
- Do not rewrite unrelated files.
- Do not remove tests to make a build pass.
- Preserve existing public APIs unless the plan explicitly changes them.
- Keep secrets out of prompts and code.

Verification:
- HOME=/private/tmp/worker-manager-home CLANG_MODULE_CACHE_PATH=/private/tmp/worker-manager-module-cache swift test --disable-sandbox
- HOME=/private/tmp/worker-manager-home CLANG_MODULE_CACHE_PATH=/private/tmp/worker-manager-module-cache swift build --disable-sandbox
- git diff --check
```

## Validation Commands

SwiftPM can hit sandbox/cache issues in Codex. Prefer:

```bash
HOME=/private/tmp/worker-manager-home \
CLANG_MODULE_CACHE_PATH=/private/tmp/worker-manager-module-cache \
swift test --disable-sandbox
```

```bash
HOME=/private/tmp/worker-manager-home \
CLANG_MODULE_CACHE_PATH=/private/tmp/worker-manager-module-cache \
swift build --disable-sandbox
```

Also run:

```bash
git diff --check
```

## Packaging

Use the project scripts:

```bash
./script/build_app_bundle.sh
./script/package_app.sh
```

Expected outputs:

- `dist/WorkerManager.app`
- `dist/WorkerManager.pkg`

The app bundle contains this skill under:

```text
Contents/Resources/CodexSkills/worker-manager/SKILL.md
```

At app startup, `CodexSkillInstaller` checks whether `~/.codex/skills/worker-manager/SKILL.md` exists. It installs the bundled skill only when the file is missing, so users can customize the installed skill without the app overwriting their edits on later launches.

The installer package also includes a postinstall script that attempts to copy the bundled skill into the active console user's Codex skills directory after installing the app to `/Applications`. The script also preserves an existing installed skill instead of overwriting it.

## Conversation Notes

Recent design decisions from this thread:

- Use three independent workspaces instead of mixing model CRUD and execution testing.
- Use multi-turn chat testing for model connectivity instead of a diff-preview-first interface.
- Keep advanced debug details such as raw response, latency, and token counts out of the first chat test implementation.
- Preserve existing worker preview behavior for compatibility while making chat testing the primary app UI.
