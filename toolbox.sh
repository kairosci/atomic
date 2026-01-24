#!/usr/bin/env zsh

podman rm -af
podman rmi -af

rm -rf ~/.local/share/containers
rm -rf ~/.config/containers

podman system migrate

toolbox create dev
toolbox run dev sudo dnf install -y zsh
toolbox run dev sudo usermod -s /usr/bin/zsh $USER
