W ?= $(realpath .)
H ?= $(realpath isabelle-home-user)
ID ?=

docker_dir := $(dir $(lastword $(MAKEFILE_LIST)))

none build run exec rm-container rm-isabelle-user-home clean:

%:
	$(MAKE) -C $(docker_dir) $@
