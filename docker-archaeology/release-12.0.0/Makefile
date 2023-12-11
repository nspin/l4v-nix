id := l4v
image_tag := $(id)
container_name := $(id)

local_target_dump_dir := target-dump
local_sample_target_dir := target-sample

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY: default
default: $(local_sample_target_dir)

.PHONY: clean
clean:
	rm -rf $(local_target_dump_dir) $(local_sample_target_dir)

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

$(local_target_dump_dir): build
	mkdir $@
	docker run --rm $(image_tag) tar -c -C graph-refine/seL4-example target | tar -x -C $@

$(local_sample_target_dir): $(local_target_dump_dir)
	mkdir $@
	rsync -av \
		--exclude='build' \
		--exclude='target.py*' \
		$^/ $@/
