# Handbrake in a Docker container with nvenc support

### Fork of jlesage/handbrake, adds NVENC Hardware encoding

In order to make this image work you need Docker >= 19.03 and the latest [NVIDIA driver](https://github.com/NVIDIA/nvidia-docker/wiki/Frequently-Asked-Questions#how-do-i-install-the-nvidia-driver) installed on your host system.

On a headless Debian server it is recommended to use the [official Nvidia installer](https://www.nvidia.com/en-us/drivers/unix/).

An official guide by Nvidia can be found [here](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installing-on-ubuntu-and-debian).

---

**NOTE:** The Docker command provided in this quick start is given as an example and parameters should be adjusted to your need.

### Supported tags

| tag             | Handbrake version | build status             |
|:---------------:|:-----------------:|:------------------------:|
| `nightly`       | master            | ![Dockerimage nightly][] |
| `18x`           | 1.8.0             | ![Dockerimage 1.8.x][]   |
| `17x`, `latest` | 1.7.3             | ![Dockerimage 1.7.x][]   |
| `16x`           | 1.6.1             | ![Dockerimage 1.6.x][]   |
| `15x`           | 1.5.1             | ![Dockerimage 1.5.x][]   |
| `14x`           | 1.4.2             | ![Dockerimage 1.4.x][]   |
| `13x`           | 1.3.x-git         | ![Dockerimage 1.3.x][]   |

[Dockerimage nightly]: https://github.com/zocker-160/handbrake-nvenc-docker/actions/workflows/dockerimage-nightly.yml/badge.svg
[Dockerimage 1.8.x]: https://github.com/zocker-160/handbrake-nvenc-docker/actions/workflows/dockerimage-18x.yml/badge.svg
[Dockerimage 1.7.x]: https://github.com/zocker-160/handbrake-nvenc-docker/actions/workflows/dockerimage-17x.yml/badge.svg
[Dockerimage 1.6.x]: https://github.com/zocker-160/handbrake-nvenc-docker/actions/workflows/dockerimage-16x.yml/badge.svg
[Dockerimage 1.5.x]: https://github.com/zocker-160/handbrake-nvenc-docker/actions/workflows/dockerimage-15x.yml/badge.svg
[Dockerimage 1.4.x]: https://github.com/zocker-160/handbrake-nvenc-docker/actions/workflows/dockerimage-14x.yml/badge.svg
[Dockerimage 1.3.x]: https://github.com/zocker-160/handbrake-nvenc-docker/actions/workflows/dockerimage-13x.yml/badge.svg

Launch the HandBrake docker container with the following command:
```
docker run -d -t \
    --name=handbrake \
    -p 5800:5800 \
    -v <replace/the/path>:/config:rw \
    -v <replace/the/path>:/storage:ro \
    -v <replace/the/path>:/watch:rw \
    -v <replace/the/path>:/output:rw \
    --gpus all \
    zocker160/handbrake-nvenc:latest
```

Docker compose `docker compose up -d`
```yml
version: '3'
services:
  handbrake:
    image: zocker160/handbrake-nvenc:18x
    container_name: handbrake
    environment:
      - AUTOMATED_CONVERSION_FORMAT=mp4
      - AUTOMATED_CONVERSION_PRESET=Creator 1080p60
    ports:
      - 5800:5800
    volumes:
      - <replace/the/path>:/config:rw
      - <replace/the/path>:/storage:ro
      - <replace/the/path>:/watch:rw
      - <replace/the/path>:/output:rw
    restart: always 
    deploy:
      resources:
        reservations:
          devices:
            - count: all
              capabilities: [gpu]
```

#### Usage

- `--gpus all` this enables the passthrough to the GPU(s)
- `Port 5800`: for WebGUI
- `Port 5900`: for VNC client connection
- `/config`: This is where the application stores its configuration, log and any files needing persistency.
- `/storage`: This location contains files from your host that need to be accessible by the application.
- `/watch`: This is where videos to be automatically converted are located.
- `/output`: This is where automatically converted video files are written.

Browse to `http://your-host-ip:5800` to access the HandBrake GUI. 

Files from the host appear under the `/storage` folder in the container.

#### Optional parameters

- `-e AUTOMATED_CONVERSION_PRESET` (default: `"Very Fast 1080p30"`)
- `-e AUTOMATED_CONVERSION_FORMAT` (default: `"mp4"`)
- `-e APP_NAME` (default: `"Handbrake"`)

additional detailed info:
<https://hub.docker.com/r/jlesage/handbrake#docker-container-for-handbrake>
