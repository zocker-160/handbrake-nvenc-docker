FROM ubuntu:18.04 AS builder


MAINTAINER zocker-160

ENV HANDBRAKE_VERSION 1.3.0
ENV HANDBRAKE_URL https://api.github.com/repos/HandBrake/HandBrake/releases/tags/$HANDBRAKE_VERSION
ENV HANDBRAKE_DEBUG_MODE none

ENV DEBIAN_FRONTEND noninteractive


WORKDIR /HB

# Compile HandBrake, libva and Intel Media SDK.
RUN apt-get update
RUN apt-get install -y \
	jq dtrx \
    # build tools.
    curl build-essential autoconf libtool-bin \
    m4 patch coreutils tar file git wget diffutils \
    # misc libraries
    libpciaccess-dev xz-utils libbz2-dev \
    # media libraries, media codecs, gtk
    libsamplerate-dev libass-dev libopus-dev libvpx-dev \
    libvorbis-dev gtk+3.0-dev libdbus-glib-1-dev \
    libnotify-dev libgudev-1.0-dev automake cmake \
    debhelper libwebkitgtk-3.0-dev libspeex-dev \
    libbluray-dev intltool libxml2-dev python python3 \
    libdvdnav-dev libdvdread-dev libgtk-3-dev \
    libjansson-dev liblzma-dev libappindicator-dev\
    libmp3lame-dev libogg-dev libglib2.0-dev ninja-build \
    libtheora-dev nasm yasm xterm libnuma-dev numactl \
    libpciaccess-dev linux-headers-generic libx264-dev

RUN wget http://mirrors.kernel.org/ubuntu/pool/universe/m/meson/meson_0.47.2-1ubuntu2_all.deb
RUN apt install -y ./meson_0.47.2-1ubuntu2_all.deb

# Download HandBrake sources
RUN echo "Downloading HandBrake sources..."
RUN curl --silent $HANDBRAKE_URL | jq -r '.assets[0].browser_download_url' | wget -i - -O "HandBrake-source.tar.bz2"
RUN dtrx -n HandBrake-source.tar.bz2
RUN rm -rf HandBrake-source.tar.bz2
# Download patches
RUN echo "Downloading patches..."
RUN curl --progress-bar -L -o /HB/HandBrake-source/HandBrake-$HANDBRAKE_VERSION/A00-hb-video-preset.patch https://raw.githubusercontent.com/jlesage/docker-handbrake/master/A00-hb-video-preset.patch
# Compile HandBrake
WORKDIR /HB/HandBrake-source/HandBrake-$HANDBRAKE_VERSION
RUN echo "Compiling HandBrake..."
RUN ./configure --prefix=/usr/local \
                --debug=$HANDBRAKE_DEBUG_MODE \
                --disable-gtk-update-checks \
                --enable-fdk-aac \
                --enable-x265 \
                --launch-jobs=$(nproc) \
                --launch

RUN make -j$(nproc) --directory=build install


# Pull base image
FROM jlesage/baseimage-gui:ubuntu-18.04

ENV DEBIAN_FRONTEND noninteractive
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all

WORKDIR /tmp

# Install dependencies.
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
        # HandBrake dependencies
        libass9 libcairo2 libgtk-3-0 libgudev-1.0-0 libjansson4 libnotify4  \
        libtheora0 libvorbis0a libvorbisenc2 speex libopus0 libxml2 numactl \
        xz-utils git libdbus-glib-1-2 lame x264 \
        # For optical drive listing:
        lsscsi \
        # For watchfolder
        bash \
        coreutils \
        yad \
        findutils \
        expect \
        tcl8.6 \
        wget
# To read encrypted DVDs
RUN wget http://www.deb-multimedia.org/pool/main/libd/libdvdcss/libdvdcss2_1.4.2-dmo1_amd64.deb
RUN apt install -y ./libdvdcss2_1.4.2-dmo1_amd64.deb
# install scripts and stuff from upstream Handbrake docker image
RUN git config --global http.sslVerify false
RUN git clone https://github.com/jlesage/docker-handbrake.git
RUN cp -r docker-handbrake/rootfs/* /
# Cleanup
RUN apt-get remove wget git -y && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    apt-get clean -y && \
    apt-get purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" title="HandBrake">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="HandBrake">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    apt-get update && \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    install_app_icon.sh "$APP_ICON_URL" && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    apt-get clean -y && \
    apt-get purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy HandBrake from base build image.
COPY --from=builder /usr/local /usr


# Set environment variables.
ENV APP_NAME="HandBrake" \
    AUTOMATED_CONVERSION_PRESET="Very Fast 1080p30" \
    AUTOMATED_CONVERSION_FORMAT="mp4" \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]
