# Handbrake in a Docker container with nvenc support

### Fork of jlesage/handbrake, adds NVENC Hardware encoding

In order to make this image work, you need Docker >= 19.03 and the latest [NVIDIA driver](https://github.com/NVIDIA/nvidia-docker/wiki/Frequently-Asked-Questions#how-do-i-install-the-nvidia-driver) driver installed on your host system.

You also need to have the [nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-docker#ubuntu-16041804-debian-jessiestretchbuster) installed.

---

**NOTE:** The Docker command provided in this quick start is given as an example and parameters should be adjusted to your need.


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

additional detailed info:
<https://hub.docker.com/r/jlesage/handbrake#docker-container-for-handbrake>
