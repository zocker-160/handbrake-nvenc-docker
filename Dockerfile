# djaydev/HandBrake:latest

# Pull base build image.
FROM debian:sid AS builder

# Define software versions.
ARG HANDBRAKE_VERSION=1.2.2

# Define software download URLs.
ARG HANDBRAKE_URL=https://download.handbrake.fr/releases/${HANDBRAKE_VERSION}/HandBrake-${HANDBRAKE_VERSION}-source.tar.bz2

# Other build arguments.

# Set to 'max' to keep debug symbols.
ARG HANDBRAKE_DEBUG_MODE=none

# Define working directory.
WORKDIR /tmp

# Compile HandBrake, libva and Intel Media SDK.
RUN \
    apt update && \
	  apt install \
    # build tools.
    curl build-essential autoconf libtool-bin \
    m4 patch coreutils tar file git \
    diffutils bash \
    # misc libraries
    libpciaccess-dev xz-utils \
    # media libraries, media codecs, gtk
    libsamplerate-dev libass-dev libopus-dev \
    libvorbis-dev gtk+3.0-dev libdbus-glib-1-dev \
    libnotify-dev libgudev-1.0-dev automake cmake \
    debhelper intltool libass-dev libavcodec-dev \
    libavfilter-dev libavformat-dev libavutil-dev \
    libbluray-dev libbz2-dev libdbus-glib-1-dev \
		libdvdnav-dev libdvdread-dev libfontconfig1-dev \
		libfreetype6-dev libgstreamer-plugins-base1.0-dev \
		libgstreamer1.0-dev libgtk-3-dev \
		libgudev-1.0-dev libjansson-dev liblzma-dev \
		libmp3lame-dev libmpeg2-4-dev libogg-dev \
		libopus-dev libsamplerate0-dev \
		libspeex-dev libswresample-dev libswscale-dev \
		libtheora-dev nasm yasm \
		libvorbis-dev libvpx-dev libx264-dev \
		libx265-dev libxml2-dev python \
		-y

RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
RUN cd nv-codec-headers && make && make install

    # Download HandBrake sources.
RUN echo "Downloading HandBrake sources..." && \
    if echo "${HANDBRAKE_URL}" | grep -q '\.git$'; then \
        git clone ${HANDBRAKE_URL} HandBrake && \
        git -C HandBrake checkout "${HANDBRAKE_VERSION}"; \
    else \
        mkdir HandBrake && \
        curl -# -L ${HANDBRAKE_URL} | tar xj --strip 1 -C HandBrake; \
    fi && \
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
    patch -p1 < A00-hb-video-preset.patch && \
    ./configure --prefix=/usr \
                --debug=$HANDBRAKE_DEBUG_MODE \
                --disable-gtk-update-checks \
                --enable-fdk-aac \
                --enable-x265 \
                --launch-jobs=$(nproc) \
                --launch \
                && \
    /tmp/run_cmd -i 600 -m "HandBrake still compiling..." make --directory=build

# Pull base image.
FROM jlesage/baseimage-gui:debian-9

WORKDIR /tmp

# Install dependencies.
RUN echo "deb http://deb.debian.org/debian sid main non-free contrib" >> /etc/apt/sources.list && \
	  apt update && \
	  DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends \
        # HandBrake dependencies
        libass9 libavcodec58 \
        libavfilter7 libavformat58 \
        libavutil56 libbluray2 \
        libc6 libdvdnav4 \
        libdvdread4 libcairo2 \
        libgstreamer-plugins-base1.0-0 \
        libgdk-pixbuf2.0-0 libglib2.0-0 \
        libgtk-3-0 libgstreamer1.0-0 \
        libgudev-1.0-0 libjansson4 \
        libpango-1.0-0 libsamplerate0 \
        libswresample3 libswscale5 \
        libtheora0 libvorbis0a \
        libvorbisenc2 libx264-155 \
        libx265-165 libxml2 \
        xz-utils wget \
        # For optical drive listing:
        lsscsi \
        # For watchfolder
        bash \
        coreutils \
        yad \
        findutils \
        expect \
		    tcl8.6 \
		    -y && \
    # To read encrypted DVDs
    wget http://www.deb-multimedia.org/pool/main/libd/libdvdcss/libdvdcss2_1.4.2-dmo1_amd64.deb && \
    apt install ./libdvdcss2_1.4.2-dmo1_amd64.deb -y && \
    # Cleanup
    apt-get remove wget -y && \
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
    sed -i "/sid/s/deb http/#deb http/g" /etc/apt/sources.list && \
    apt update && \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    install_app_icon.sh "$APP_ICON_URL" && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    apt-get clean -y && \
    apt-get purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add files.
COPY rootfs/ /
# Copy HandBrake from base build image.
COPY --from=builder /tmp/HandBrake/build/HandBrakeCLI /usr/local/bin
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
