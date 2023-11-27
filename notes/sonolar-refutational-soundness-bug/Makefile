.PHONY: show
show:
	image=$$(docker build -f Dockerfile context -q) && \
		docker run --rm -it \
			$$image \
			./show.sh
