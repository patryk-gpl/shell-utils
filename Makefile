.PHONY: help install

.DEFAULT_GOAL := help

help:
	@echo "Usage: make <target>"
	@echo -e "Available targets:\n"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort
	@echo ""

# Git hooks
install: ## Install dependecies and init Git hooks
	@poetry install
	@poetry run pre-commit install

test: ## Run unit test for functions
	@bats -r tests/functions

update-hooks: ## Update Git hooks versions
	@poetry run pre-commit autoupdate

run-hooks: ## Run pre-commit hooks on the current repository for all files
	@poetry run pre-commit run --all-files
