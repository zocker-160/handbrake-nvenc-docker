# Handbrake in a Docker container with nvenc support

### Fork of jlesage/handbrake, adds NVENC Hardware encoding

In order to make this image work, you need to have [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker) installed in order to enable passthru to the nvidia card(s).

You will also need to have the [Nvidia-CUDA-toolkit](https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64)  to be installed.

---

**NOTE:** The Docker command provided in this quick start is given as an example and parameters should be adjusted to your need.


Launch the HandBrake docker container with the following command:
```
docker run -d -t \
    --name=handbrake \
    --runtime=nvidia \
    -p 5800:5800 \
    -v /docker/appdata/handbrake:/config:rw \
    -v $HOME:/storage:ro \
    -v $HOME/HandBrake/watch:/watch:rw \
    -v $HOME/HandBrake/output:/output:rw \
    zocker160/handbrake-nvenc:latest
```
#### Usage

- `--runtime=nvidia` this enables the passthrough to the GPU(s)
- `/docker/appdata/handbrake`: This is where the application stores its configuration, log and any files needing persistency.
- `Port 5800`: for WebGUI
- `Port 5900`: for VNC client connection
- `$HOME`: This location contains files from your host that need to be accessible by the application.
- `$HOME/HandBrake/watch`: This is where videos to be automatically converted are located.
- `$HOME/HandBrake/output`: This is where automatically converted video files are written.

Browse to `http://your-host-ip:5800` to access the HandBrake GUI. 

Files from the host appear under the `/storage` folder in the container.

additional detailed info:
<https://hub.docker.com/r/jlesage/handbrake#docker-container-for-handbrake>
