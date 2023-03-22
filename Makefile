SHELL:=/bin/bash

.PHONY: install
install: ## make install # Install dependencies
	@rbenv install -s
	@gem install overcommit && overcommit --install && overcommit --sign pre-commit
	@tfenv install

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
