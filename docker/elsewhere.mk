ID ?= elsewhere
W ?= $(abspath .)
H ?= $(abspath isabelle-home-user)

params := \
	W \
	H \
	UPSTREAM_ISABELLE \
	C \
	A \
	P \
	ID \

propagate = $(if $($(1)),$(1)=$($(1)))

docker_dir := $(dir $(lastword $(MAKEFILE_LIST)))

none build run exec rm-container rm-isabelle-user-home clean:

%:
	$(MAKE) \
		-C $(docker_dir) \
		$(foreach param,$(params),$(call propagate,$(param))) \
		$@
