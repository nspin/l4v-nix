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

local_target_dir := target

$(local_target_dir): build
	mkdir $(local_target_dir)
	docker run --rm $(image_tag) tar -c -C graph-refine/seL4-example target | tar -x -C $(local_target_dir)

.PHONY: clean
clean:
	rm -rf $(local_target_dir)
