REGISTRY_IMAGE=ghcr.io/rwunderer/kivitendo
KIVITENDO_VERSION=3.8.0

.PHONY:	all
all: build test

.PHONY:	build
build:
	docker build --build-arg=BUILD_KIVITENDO_VERSION=$(KIVITENDO_VERSION) -t $(REGISTRY_IMAGE) .

.PHONY:	test
test:
	docker run --rm -it $(REGISTRY_IMAGE)

.PHONY: clean
clean:
	docker image rm $(REGISTRY_IMAGE)
