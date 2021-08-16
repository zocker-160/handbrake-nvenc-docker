FROM debian:10 AS builder

MAINTAINER zocker-160

ENV HANDBRAKE_VERSION_TAG 1.4.0
ENV HANDBRAKE_VERSION_BRANCH 1.4.x
ENV HANDBRAKE_DEBUG_MODE none

ENV HANDBRAKE_URL https://api.github.com/repos/HandBrake/HandBrake/releases/tags/$HANDBRAKE_VERSION
ENV HANDBRAKE_URL_GIT https://github.com/HandBrake/HandBrake.git

ENV DEBIAN_FRONTEND noninteractive


WORKDIR /HB

## Prepare
RUN apt-get update
RUN apt-get install -y \
    curl diffutils file coreutils m4 xz-utils nasm python3 python3-pip

## Install dependencies
RUN apt-get install -y \
    autoconf automake build-essential cmake git libass-dev libbz2-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev libjansson-dev liblzma-dev libmp3lame-dev libnuma-dev libogg-dev libopus-dev libsamplerate-dev libspeex-dev libtheora-dev libtool libtool-bin libturbojpeg0-dev libvorbis-dev libx264-dev libxml2-dev libvpx-dev m4 make nasm ninja-build patch pkg-config python tar zlib1g-dev
    
## Intel CSV dependencies
RUN apt-get install -y libva-dev libdrm-dev
    
## GTK GUI dependencies
RUN apt-get install -y \ 
    intltool libappindicator-dev libdbus-glib-1-dev libglib2.0-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgtk-3-dev libgudev-1.0-dev libnotify-dev libwebkit2gtk-4.0-dev

## Install meson from pip
RUN pip3 install -U meson

## Download HandBrake sources
RUN echo "Downloading HandBrake sources..."
RUN git clone $HANDBRAKE_URL_GIT

## Compile HandBrake
WORKDIR /HB/HandBrake

RUN git checkout $HANDBRAKE_VERSION_TAG
RUN ./scripts/repo-info.sh > version.txt

RUN echo "Compiling HandBrake..."
RUN ./configure --prefix=/usr/local \
                --debug=$HANDBRAKE_DEBUG_MODE \
                --disable-gtk-update-checks \
                --enable-x265 \
                --enable-numa \
                --enable-nvenc \
                --enable-qsv \                
                --launch-jobs=$(nproc) \
                --launch

RUN make -j$(nproc) --directory=build install
