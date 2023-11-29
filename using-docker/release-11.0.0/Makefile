id := l4v
image_tag := $(id)
container_name := $(id)

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY: build
build:
	docker buildx build \
		--build-arg UID=$(uid) --build-arg GID=$(gid) \
		-t $(image_tag) \
		.

		# --progress=plain \

.PHONY: run
run: build
	docker run --rm -it \
		$(image_tag)
