DOCKER_NAME = "madminer-workflow-ml"
DOCKER_REGISTRY = "madminertool"
DOCKER_VERSION = $(shell cat VERSION)

MLFLOW_USERNAME ?= $(shell whoami)
MLFLOW_TRACKING_URI ?= "file:///_mlflow"

YADAGE_INPUT_DIR = "$(PWD)/workflow"
YADAGE_SPEC_DIR = "$(PWD)/workflow/yadage"
YADAGE_WORK_DIR = "$(PWD)/.yadage"

WORKFLOW_DIR = "$(PWD)/workflow/yadage"
WORKFLOW_FILE = "workflow.yml"
WORKFLOW_NAME = "madminer-workflow-ml"

INPUT_DIR="$(PWD)/workflow"
DATA_FILE="$(PWD)/data/combined_delphes.h5"


.PHONY: check
check:
	@echo "Checking code format"
	@black --check "code"


.PHONY: build
build:
	@echo "Building Docker image..."
	@docker build . --tag $(DOCKER_REGISTRY)/$(DOCKER_NAME):$(DOCKER_VERSION)


.PHONY: push
push: build
	@echo "Pushing Docker image..."
	@docker login --username "${DOCKERUSER}" --password "${DOCKERPASS}"
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_NAME):$(DOCKER_VERSION)


.PHONY: reana-check
reana-check:
	@echo "Checking REANA spec..."
	@cd $(WORKFLOW_DIR) && reana-client validate --environments


.PHONY: reana-run
reana-run: 
	@echo "Deploying on REANA..."
	@cd $(WORKFLOW_DIR) && \
		reana-client create -n $(WORKFLOW_NAME) && \
		reana-client upload -w $(WORKFLOW_NAME) . 
	@reana-client upload -w $(WORKFLOW_NAME) $(INPUT_DIR) && \
	 reana-client upload -w $(WORKFLOW_NAME) $(DATA_FILE) && \
	 reana-client start -w $(WORKFLOW_NAME) \
			-p mlflow_server=$(MLFLOW_TRACKING_URI) \
			-p mlflow_username=$(MLFLOW_USERNAME)


.PHONY: yadage-clean
yadage-clean:
	@echo "Cleaning previous run..."
	@rm -rf $(YADAGE_WORK_DIR)


.PHONY: yadage-run
yadage-run: yadage-clean
	@echo "Launching Yadage..."
	@yadage-run $(YADAGE_WORK_DIR) "workflow.yml" \
		-p data_file="/madminer/data/combined_delphes.h5" \
		-p input_file="input.yml" \
		-p mlflow_args_s="\"'n_samples_train=100000'\"" \
		-p mlflow_args_t="\"'num_epochs=50 alpha=0.1 batch_size=128'\"" \
		-p mlflow_args_e="\"''\"" \
		-p mlflow_server=$(MLFLOW_TRACKING_URI) \
		-p mlflow_username=$(MLFLOW_USERNAME) \
		-d initdir=$(YADAGE_INPUT_DIR) \
		--toplevel $(YADAGE_SPEC_DIR)
