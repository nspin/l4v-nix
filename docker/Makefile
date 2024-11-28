# For run
W ?= ../projects
H ?= isabelle-home-user
UPSTREAM_ISABELLE ?= 0

# For exec
C ?= RISCV64_MCS
A ?= $(C).l4vEnv
P ?= 1
ID ?= sel4-verification-reproducibility-mcs-sorry

ifeq ($(ID),)
	$(error foo)
endif

work_local_path := $(W)
work_remote_path:= /work

ifeq ($(UPSTREAM_ISABELLE),1)
	nix_isabelle_attr := upstreamIsabelleForL4v
else
	nix_isabelle_attr := seL4IsabelleForL4v
endif

isabelle_home_user_local_path := $(H)

nix_expr_path := ..
nix_shell_attr := $(A)

ifeq ($(P),1)
	nix_shell_pure_arg := --pure
endif

id := $(ID)
image_tag := $(id)
container_name := $(id)

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY: none
none:

.PHONY: clean
clean: rm-container rm-isabelle-user-home

.PHONY: build
build:
	docker build \
		--build-arg UID=$(uid) \
		--build-arg GID=$(gid) \
		-t $(image_tag) .

.PHONY: run
run: build | $(isabelle_home_user_local_path)
	docker run -d --rm \
		--name $(container_name) \
		--tmpfs /tmp:exec \
		--mount type=bind,src=/nix/store,dst=/nix/store,ro \
		--mount type=bind,src=/nix/var/nix/db,dst=/nix/var/nix/db,ro \
		--mount type=bind,src=/nix/var/nix/daemon-socket,dst=/nix/var/nix/daemon-socket,ro \
		--mount type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix,ro \
		--mount type=bind,src=$(abspath $(isabelle_home_user_local_path)),dst=/home/x/.isabelle \
		--mount type=bind,src=$$(echo $$(nix-build $(nix_expr_path) -A $(nix_isabelle_attr) --no-out-link)/Isabelle*),dst=$(work_remote_path)/isabelle,ro \
		--mount type=bind,src=$(abspath $(work_local_path))/seL4,dst=$(work_remote_path)/seL4,ro \
		--mount type=bind,src=$(abspath $(work_local_path))/l4v,dst=$(work_remote_path)/l4v \
		$(image_tag) \
		$$(nix-build $(nix_expr_path) -A setupEnv --no-out-link)

.PHONY: exec
exec:
	container_xauthority=$$(nix-build $(nix_expr_path) -A containerXauthority --no-out-link)/bin/container-xauthority && \
	$$container_xauthority env-host \
		docker exec -it \
			--env DISPLAY \
			--env XAUTHORITY_CONTENTS \
			$(container_name) \
			$$container_xauthority env-container \
				$$(nix-build $(nix_expr_path) -A pkgs.nix --no-out-link)/bin/nix-shell \
					$$(nix-instantiate $(nix_expr_path) -A $(nix_shell_attr)) \
					$(nix_shell_pure_arg)

.PHONY: rm-container
rm-container:
	for id in $$(docker ps -aq -f "name=^$(container_name)$$"); do \
		docker rm -f $$id; \
	done

$(isabelle_home_user_local_path):
	mkdir -p $@

.PHONY: rm-isabelle-user-home
rm-isabelle-user-home:
	rm -rf $(isabelle_home_user_local_path)
