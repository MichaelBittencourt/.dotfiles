FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN printf '#!/bin/sh\nexec "$@"\n' > /usr/local/bin/sudo \
    && chmod +x /usr/local/bin/sudo

COPY . /root/.dotfiles

WORKDIR /root

RUN bash /root/.dotfiles/install_dependencies.sh --all \
    && bash /root/.dotfiles/install.sh --all

RUN mkdir -p /workspace

WORKDIR /workspace

CMD ["bash"]
