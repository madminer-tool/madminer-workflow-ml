DOCKER_NAME=madminer-workflow-ml
DOCKER_REGISTRY=madminertool
DOCKER_VERSION=$(shell cat ./VERSION)

YADAGE_INITIAL_STEP="init"

YADAGE_INPUT_DIR="$(PWD)/workflow"
YADAGE_SPEC_DIR="$(PWD)/workflow/yadage"
YADAGE_WORKDIR="$(PWD)/.yadage"


all: build push yadage-adapt yadage-clean yadage-run


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


## ------------------------- CLARIFICATION -------------------------
## This rule is necessary to allow the execution of the ML workflow
## As a sub-workflow in the "Scailfin/madminer-workflow" wrapper repo.
## -----------------------------------------------------------------

.PHONY: yadage-adapt
yadage-adapt:
	@echo "Adapting Workflow to isolated run..."
	@sed -i "" "s/{data_step}/$(YADAGE_INITIAL_STEP)/g" "$(YADAGE_SPEC_DIR)/workflow.yml"


.PHONY: yadage-clean
yadage-clean:
	@echo "Cleaning previous run..."
	@rm -rf $(YADAGE_WORKDIR)


.PHONY: yadage-run
yadage-run: yadage-clean
	@echo "Launching Yadage..."
	@yadage-run $(YADAGE_WORKDIR) "workflow.yml" \
		-p data_file="data/dummy_data.h5" \
		-p input_file="input.yml" \
		-p train_samples="1" \
		-d initdir=$(YADAGE_INPUT_DIR) \
		--toplevel $(YADAGE_SPEC_DIR)
