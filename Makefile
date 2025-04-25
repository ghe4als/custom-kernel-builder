# Makefile for kernel build project

# Variables
DOCKER_IMAGE_NAME := custom-kernel-builder
DOCKER_IMAGE_TAG := latest
DOCKER_FULL_NAME := $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
COLIMA_CPU := 4
COLIMA_MEM := 8
COLIMA_DISK := 50

# Default target
.PHONY: all
all: build

# Start Colima with appropriate resources
.PHONY: colima-start
colima-start:
	@echo "Starting Colima with $(COLIMA_CPU) CPUs and $(COLIMA_MEM)GB RAM..."
	colima start --cpu $(COLIMA_CPU) --memory $(COLIMA_MEM) --disk $(COLIMA_DISK) || true
	@echo "Waiting for Docker daemon to be ready..."
	sleep 5

# Stop Colima
.PHONY: colima-stop
colima-stop:
	@echo "Stopping Colima..."
	colima stop

# Build the Docker image
.PHONY: build
build: colima-start
	@echo "Building Docker image: $(DOCKER_FULL_NAME)..."
	docker build -t $(DOCKER_FULL_NAME) .

# Clean built image
.PHONY: clean
clean:
	@echo "Removing Docker image: $(DOCKER_FULL_NAME)..."
	docker rmi $(DOCKER_FULL_NAME) || true

# Run a shell in the container for testing
.PHONY: shell
shell: build
	@echo "Running shell in container..."
	docker run --rm -it --privileged \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/kernel \
		-w /kernel \
		$(DOCKER_FULL_NAME) bash

# Run the kernel build manually (outside of Jenkins)
.PHONY: build-kernel
build-kernel: build
	@echo "Building kernel in container..."
	docker run --rm --privileged \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/kernel \
		-v kernel-build-cache:/tmp/kernel-build \
		-w /kernel \
		$(DOCKER_FULL_NAME) ./build_kernel.sh

# Create Docker volume for build cache
.PHONY: create-volume
create-volume:
	@echo "Creating Docker volume for build cache..."
	docker volume create kernel-build-cache || true

# Remove Docker volume
.PHONY: remove-volume
remove-volume:
	@echo "Removing Docker volume..."
	docker volume rm kernel-build-cache || true

# Full reset - stop everything and clean up
.PHONY: reset
reset: clean remove-volume colima-stop
	@echo "Environment reset completed."

# Help target
.PHONY: help
help:
	@echo "Kernel Build Project Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  all           : Default target, builds the Docker image"
	@echo "  build         : Build the Docker image"
	@echo "  colima-start  : Start Colima with configured resources"
	@echo "  colima-stop   : Stop Colima"
	@echo "  shell         : Run a shell in the container for testing"
	@echo "  build-kernel  : Build the kernel manually (outside of Jenkins)"
	@echo "  clean         : Remove the Docker image"
	@echo "  create-volume : Create Docker volume for build cache"
	@echo "  remove-volume : Remove Docker volume"
	@echo "  reset         : Full reset - remove image, volume, and stop Colima"
	@echo "  help          : Show this help message"
