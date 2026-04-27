#!/bin/bash
# run_docker_creation.sh

docker run \
	--network host \
	--cap-add=NET_RAW \
	--cap-add=NET_ADMIN \
	--mount type=bind,src=/home/$USER/kali-workspace,dst=/kali-workspace \
	--tty --interactive \
	--name kali \
	kalilinux/kali-rolling
