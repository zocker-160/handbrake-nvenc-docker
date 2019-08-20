# djaydev/HandBrake:latest

# Pull base build image.
FROM ubuntu:18.04 AS builder

# Define software versions.
ARG HANDBRAKE_VERSION=1.2.2

# Define software download URLs.
ARG HANDBRAKE_URL=https://github.com/HandBrake/HandBrake.git

# Other build arguments.

# Set to 'max' to keep debug symbols.
ARG HANDBRAKE_DEBUG_MODE=none

# Define working directory.
WORKDIR /tmp

# Compile HandBrake, libva and Intel Media SDK.
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install \
    # build tools.
    curl build-essential autoconf libtool-bin \
    m4 patch coreutils tar file git diffutils \
    # misc libraries
    libpciaccess-dev xz-utils libbz2-dev \
    # media libraries, media codecs, gtk
    libsamplerate-dev libass-dev libopus-dev libvpx-dev \
    libvorbis-dev gtk+3.0-dev libdbus-glib-1-dev \
    libnotify-dev libgudev-1.0-dev automake cmake \
    debhelper libwebkitgtk-3.0-dev libspeex-dev \
    libbluray-dev intltool libxml2-dev python \
    libdvdnav-dev libdvdread-dev libgtk-3-dev \
    libjansson-dev liblzma-dev libappindicator-dev\
    libmp3lame-dev libogg-dev libglib2.0-dev  \
    libtheora-dev nasm yasm xterm libnuma-dev \
    libpciaccess-dev linux-headers-generic libx264-dev -y

RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
RUN cd nv-codec-headers && make -j$(nproc) && make install

    # Download HandBrake sources.
RUN echo "Downloading HandBrake sources..." && \
        git clone ${HANDBRAKE_URL} HandBrake && \
    # Download helper.
    echo "Downloading helpers..." && \
    curl -# -L -o /tmp/run_cmd https://raw.githubusercontent.com/jlesage/docker-mgmt-tools/master/run_cmd && \
    chmod +x /tmp/run_cmd && \
    # Download patches.
    echo "Downloading patches..." && \
    curl -# -L -o HandBrake/A00-hb-video-preset.patch https://raw.githubusercontent.com/jlesage/docker-handbrake/master/A00-hb-video-preset.patch && \
    # Compile HandBrake.
    echo "Compiling HandBrake..." && \
    cd HandBrake && \
    ./configure --prefix=/usr \
                --debug=$HANDBRAKE_DEBUG_MODE \
                --disable-gtk-update-checks \
                --enable-fdk-aac \
                --enable-x265 \
                --launch-jobs=$(nproc) \
                --launch \
                && \
    /tmp/run_cmd -i 600 -m "HandBrake still compiling..." make -j$(nproc) --directory=build

# Pull base image.
FROM jlesage/baseimage-gui:ubuntu-18.04

WORKDIR /tmp

# Install dependencies.
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends \
        # HandBrake dependencies
        libass9 speex libbluray2 libdvdnav4 libdvdread4 libcairo2 \
        libgtk-3-0 libgudev-1.0-0 libjansson4 libnotify4 libopus0 \
        libsamplerate0 libtheora0 libvorbis0a libvorbisenc2 libxml2 \
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
        wget -y && \
    # To read encrypted DVDs
    wget http://www.deb-multimedia.org/pool/main/libd/libdvdcss/libdvdcss2_1.4.2-dmo1_amd64.deb && \
    apt install ./libdvdcss2_1.4.2-dmo1_amd64.deb -y && \
    # install scripts and stuff from upstream Handbrake docker image
    git config --global http.sslVerify false && \
    git clone https://github.com/jlesage/docker-handbrake.git && \
    cp -r docker-handbrake/rootfs/* / && \
    # Cleanup
    apt-get remove wget git -y && \
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
    apt update && \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    install_app_icon.sh "$APP_ICON_URL" && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    apt-get clean -y && \
    apt-get purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy HandBrake from base build image.
COPY --from=builder /tmp/HandBrake/build/HandBrakeCLI /usr/bin
COPY --from=builder /tmp/HandBrake/build/gtk/src /usr/bin

# Set environment variables.
ENV APP_NAME="HandBrake" \
    AUTOMATED_CONVERSION_PRESET="Very Fast 1080p30" \
    AUTOMATED_CONVERSION_FORMAT="mp4"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]
