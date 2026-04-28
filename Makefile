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

.PHONY: push build run run-sim

# Push to GitHub
push: ## 🛡️ Auto-commit + Push
	@echo ""
	@echo "🚀 Running smart push..."
	@$(PYTHON_CMD) scripts/autocommit.py

# Build the macOS App
build: ## 🔨 Build NeuroPilotApp
	@echo "🔨 Building NeuroPilotApp..."
	@cd NeuroPilotApp && xcodebuild -project NeuroPilotApp.xcodeproj -scheme NeuroPilotApp -configuration Debug -derivedDataPath build build

# Run the macOS App
run: build ## 🚀 Run NeuroPilotApp
	@echo "🚀 Launching NeuroPilotApp..."
	@open NeuroPilotApp/build/Build/Products/Debug/NeuroPilotApp.app

# Run the Neural Simulator
run-sim: ## 🧠 Run Neural Simulator
	@echo "🧠 Starting Neural Simulator..."
	@$(PYTHON_CMD) simulator/main.py
