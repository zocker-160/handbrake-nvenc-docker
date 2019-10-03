FROM jlesage/baseimage-gui:ubuntu-18.04

MAINTAINER zocker-160, jlesage

ENV DEBIAN_FRONTEND noninteractive
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all

# Install needed packages
RUN apt-get update
RUN apt-get install -y software-properties-common apt-utils

# Install Handbrake from PPA
RUN apt-get update
RUN add-apt-repository -y ppa:stebbins/handbrake-releases
RUN apt-get update
RUN apt-get install -y handbrake-gtk

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

# Set environment variables.
ENV APP_NAME="HandBrake"
ENV AUTOMATED_CONVERSION_PRESET="Very Fast 1080p30"
ENV AUTOMATED_CONVERSION_FORMAT="mp4"
# ENV DISPLAY :1

WORKDIR /tmp
# Add startapp script
COPY startapp.sh /startapp.sh

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]
