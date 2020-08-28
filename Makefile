DOCKER_NAME=madminer-workflow-ml
DOCKER_REGISTRY=madminertool
DOCKER_VERSION=$(shell cat ./VERSION)

MLFLOW_USERNAME ?= $(shell whoami)
MLFLOW_TRACKING_URI ?= "/tmp/mlflow"

YADAGE_INPUT_DIR="$(PWD)/workflow"
YADAGE_SPEC_DIR="$(PWD)/workflow/yadage"
YADAGE_WORKDIR="$(PWD)/.yadage"


all: build push yadage-clean yadage-run


.PHONY: build
build:
	@docker build . \
		--tag $(DOCKER_REGISTRY)/$(DOCKER_NAME):$(DOCKER_VERSION) \
		--tag $(DOCKER_REGISTRY)/$(DOCKER_NAME):latest


.PHONY: push
push: build
	@docker login --username "${DOCKERUSER}" --password "${DOCKERPASS}"
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_NAME):$(DOCKER_VERSION)
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_NAME):latest


.PHONY: yadage-clean
yadage-clean:
	@echo "Cleaning previous run..."
	@rm -rf $(YADAGE_WORKDIR)


.PHONY: yadage-run
yadage-run: yadage-clean
	@echo "Launching Yadage..."
	@yadage-run $(YADAGE_WORKDIR) "workflow.yml" \
		-p data_file="/madminer/data/dummy_data.h5" \
		-p input_file="input.yml" \
		-p mlflow_args_s="\"''\"" \
		-p mlflow_args_t="\"''\"" \
		-p mlflow_args_e="\"''\"" \
		-p mlflow_server=$(MLFLOW_TRACKING_URI) \
		-p mlflow_username=$(MLFLOW_USERNAME) \
		-d initdir=$(YADAGE_INPUT_DIR) \
		--toplevel $(YADAGE_SPEC_DIR)
