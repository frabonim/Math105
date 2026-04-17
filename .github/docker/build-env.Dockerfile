FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      pandoc \
      python3 \
      texlive-fonts-recommended \
      texlive-latex-recommended \
      texlive-latex-extra \
      texlive-pictures \
      texlive-fonts-extra \
      texlive-fonts-extra-links \
    && rm -rf /var/lib/apt/lists/*
