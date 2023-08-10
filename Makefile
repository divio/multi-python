IMAGE_NAME = registry.gitlab.com/divio/incubator/multi-python
TARGET ?= amd64

lint:
	docker run --rm -e LINT_FILE_DOCKER=Dockerfile -v $(CURDIR):/app divio/lint /bin/lint ${ARGS}

build:
	docker build -t ${IMAGE_NAME} --platform linux/${TARGET} .
