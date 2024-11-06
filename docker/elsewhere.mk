ID ?= elsewhere
W ?= $(abspath .)
H ?= $(abspath isabelle-home-user)

C ?= ARM

docker_dir := $(dir $(lastword $(MAKEFILE_LIST)))

none build run exec rm-container rm-isabelle-user-home clean:

%:
	$(MAKE) \
		-C $(docker_dir) \
		ID=$(ID) \
		W=$(W) \
		H=$(H) \
		C=$(C) \
		$@
