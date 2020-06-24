DOCKER_NAME=madminer-workflow-ml
DOCKER_REGISTRY=madminertool
DOCKER_VERSION=$(shell cat ./VERSION)

YADAGE_INPUT_DIR="$(PWD)/workflow"
YADAGE_SPEC_DIR="$(PWD)/workflow/yadage"
YADAGE_WORKDIR="$(PWD)/.yadage"


all: build push yadage-clean yadage-run


.PHONY: build
build:
	@docker build . --tag $(REGISTRY)/$(NAME):$(VERSION) --tag $(REGISTRY)/$(NAME):latest


.PHONY: push
push: build
	@docker login --username "${DOCKERUSER}" --password "${DOCKERPASS}"
	@docker push $(REGISTRY)/$(NAME):$(VERSION)
	@docker push $(REGISTRY)/$(NAME):latest


.PHONY: yadage-clean
yadage-clean:
	@echo "Cleaning previous run..."
	@rm -rf $(YADAGE_WORKDIR)


.PHONY: yadage-run
yadage-run: yadage-clean
	@echo "Launching Yadage..."
	@yadage-run $(YADAGE_WORKDIR) "workflow.yml" \
		-p input_file="input.yml" \
		-p train_samples="1" \
		-d initdir=$(YADAGE_INPUT_DIR) \
		--toplevel $(YADAGE_SPEC_DIR) \
		--visualize