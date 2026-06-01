# Worker Manager

Worker Manager 是一款 macOS 应用与 CLI 工具，用于配置 AI 模型供应商并调度执行任务。它提供 SwiftUI 界面来管理供应商、发现模型和执行任务，同时提供 CLI 接口支持无界面/自动化工作流。

## 项目结构

```
WorkerManager/
├── Package.swift              # SwiftPM 清单（macOS 13+）
├── Packages/
│   ├── Core/                  # 领域模型、Keychain、HTTP 客户端、存储
│   ├── ProviderFeature/       # 供应商增删改查、连接测试、SwiftUI 视图
│   ├── ModelFeature/          # 模型发现、自定义模型管理、SwiftUI 视图
│   ├── ExecutionFeature/      # Worker 任务执行、CLI 命令构建、SwiftUI 视图
│   ├── SharedUI/              # 可复用 UI 组件（空状态页、状态栏）
│   └── CLI/                   # worker-manager-cli 命令行入口
├── WorkerManagerApp/          # SwiftUI 应用入口
└── docs/                      # 设计文档与规划
```

## 构建与测试

```bash
swift build
swift test
```

## 运行

```bash
# 图形界面应用
swift run WorkerManagerApp

# 命令行工具
swift run worker-manager-cli run \
  --model deepseek-v4-pro \
  --task-file /tmp/worker-task.md \
  --workspace /path/to/project
```

## 配置供应商

1. 打开应用。
2. 添加供应商：
   - 名称：`DeepSeek`
   - 类型：`deepSeek`
   - Base URL：`https://api.deepseek.com`
   - API Key：你的密钥
3. 点击 **Fetch Models** 发现可用模型。
4. 添加自定义模型（如 `deepseek-v4-pro`）。

## 配置文件位置

- 供应商/模型元数据：`~/.worker-manager/config.json`
- API 密钥：macOS Keychain（`com.worker-manager.credentials`）

## 许可证

详见 [LICENSE](LICENSE)。