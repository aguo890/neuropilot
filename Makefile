# Variables
ifeq ($(OS),Windows_NT)
    PYTHON_CMD := python
else
    PYTHON_CMD := $(shell command -v python > /dev/null 2>&1 && echo python || echo python3)
endif

.PHONY: push

# Push to GitHub
push: ## 🛡️ Auto-commit + Push
	@echo ""
	@echo "🚀 Running smart push..."
	@$(PYTHON_CMD) scripts/autocommit.py
