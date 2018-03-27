SHELL := /bin/bash
MKFILE_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

DYSK_CLI_TAG ?= khenidak/dysk-cli:0.6
DYSK_INSTALLER_TAG ?= khenidak/dysk-installer:0.6
DYSK_FLEXVOL_INSTALLER_TAG ?= khenidak/dysk-flexvol-installer:0.6

MODULE_DIR = "$(MKFILE_DIR)/module"
CLI_DIR = "$(MKFILE_DIR)/dyskctl"
TOOLS_CLI = "$(MKFILE_DIR)/tools/dysk-cli"
FLEXVOL_DIR="$(MKFILE_DIR)/kubernetes"
TOOLS_FLEXVOL_INSTALLER="$(MKFILE_DIR)/tools/flexvol-installer"
TOOLS_DYSK_INSTALLER = "$(MKFILE_DIR)/tools/dysk-installer"
VERIFICATION_SCRIPT="$(MKFILE_DIR)/tools/verification/verify.sh"

.PHONY: help build-module clean-module build-cli clean-cli push-cli-image
## Self help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build-module: ## builds kernel module
	$(MAKE) -C $(MODULE_DIR) all

install-module: | build-module ## installs kernel module
	@if [[ "" !=  "1`lsmod | egrep dysk`"  ]]; then \
		echo "module already installed"; \
	else \
		sudo insmod "$(MKFILE_DIR)/module/dysk.ko"; \
	fi

verify: ## runs verification tests
	@$(VERIFICATION_SCRIPT) "VERIFY"

verify-perf: ## runs perf tests
	@$(VERIFICATION_SCRIPT) "PERF"

clean-module: ## cleans kernel module
	$(MAKE) -C $(MODULE_DIR) clean

build-cli: ## build dysk cli
	$(MAKE) -C $(CLI_DIR) deps build

clean-cli: ## clean dysk cli
	$(MAKE) -C $(CLI_DIR) clean

push-cli-image: #| build-cli ## build + push dysk cli docker image
	@cp $(CLI_DIR)/dyskctl $(TOOLS_CLI)/dyskctl
	@docker build --tag $(DYSK_CLI_TAG) $(TOOLS_CLI)
	# TODO: Check before push for existing image..
	@docker push $(DYSK_CLI_TAG)
	@rm $(TOOLS_CLI)/dyskctl

push-dysk-installer-image: ## build + push kernel module installer docker iamge
	#TODO: parameterize tag used by scirpt to install the module
	@docker build --tag $(DYSK_INSTALLER_TAG) $(TOOLS_DYSK_INSTALLER)
	@docker push $(DYSK_INSTALLER_TAG)

push-flexvol-installer-image: #| build-cli ## build + push dysk flex vol installer
	@cp $(CLI_DIR)/dyskctl $(TOOLS_FLEXVOL_INSTALLER)/dyskctl
	@cp $(FLEXVOL_DIR)/dysk  $(TOOLS_FLEXVOL_INSTALLER)/dysk
	@docker build --tag $(DYSK_FLEXVOL_INSTALLER_TAG) $(TOOLS_FLEXVOL_INSTALLER)
	# TODO: Check before push for existing image..
	@docker push $(DYSK_FLEXVOL_INSTALLER_TAG)
	@rm $(TOOLS_FLEXVOL_INSTALLER)/dyskctl
	@rm $(TOOLS_FLEXVOL_INSTALLER)/dysk


