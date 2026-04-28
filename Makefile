# Variables
# Prefer .venv if it exists
ifeq ($(wildcard .venv/bin/python),)
    ifeq ($(OS),Windows_NT)
        PYTHON_CMD := python
    else
        PYTHON_CMD := $(shell command -v python > /dev/null 2>&1 && echo python || echo python3)
    endif
else
    PYTHON_CMD := .venv/bin/python
endif

.PHONY: setup push build run run-sim help clean

# 🆘 Help
help: ## ℹ️ Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Setup Environment
setup: ## 🛠️ Initialize Virtual Environment
	@echo "🛠️ Creating virtual environment..."
	@python3 -m venv .venv
	@echo "📦 Installing dependencies..."
	@.venv/bin/pip install -r requirements.txt
	@echo "✅ Setup complete."

# Push to GitHub
push: ## 🛡️ Auto-commit + Push
	@echo ""
	@echo "🚀 Running smart push..."
	@$(PYTHON_CMD) scripts/autocommit.py

# Build the macOS App
build: ## 🔨 Build NeuroPilotApp
	@echo "🔨 Building NeuroPilotApp..."
	@cd NeuroPilotApp/NeuroPilot && xcodebuild -project NeuroPilot.xcodeproj -scheme NeuroPilot -configuration Debug -derivedDataPath build build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run the macOS App
run: build ## 🚀 Run NeuroPilotApp
	@echo "🛑 Stopping any running instances..."
	@pkill NeuroPilot || true
	@echo "🚀 Launching NeuroPilotApp..."
	@open NeuroPilotApp/NeuroPilot/build/Build/Products/Debug/NeuroPilot.app

# Run the Neural Simulator
run-sim: ## 🧠 Run Neural Simulator
	@echo "🧠 Starting Neural Simulator..."
	@$(PYTHON_CMD) simulator/main.py

# Clean Build Artifacts
clean: ## 🧹 Clean build artifacts
	@echo "🧹 Cleaning..."
	@rm -rf NeuroPilotApp/NeuroPilot/build
	@echo "✅ Cleaned."
