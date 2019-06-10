# docker-handbrake

# Fork of jlesage/handbrake, adds NVENC, removes Intel Quick Sync

Handbrake GUI with Web browser and VNC access. Supports NVENC encoding

Requires
```
--runtime=nvidia
-e NVIDIA_DRIVER_CAPABILITIES=all
```
Example run
```
docker run -d \
    --name=handbrake \
    --runtime=nvidia \
    -p 5800:5800 \
    -p 5900:5900 \
    -v /docker/appdata/handbrake:/config:rw \
    -v $HOME:/storage:ro \
    -v $HOME/HandBrake/watch:/watch:rw \
    -v $HOME/HandBrake/output:/output:rw \
    -e NVIDIA_DRIVER_CAPABILITIES=all
    djaydev/handbrake
```
Where:

- `/docker/appdata/handbrake`: This is where the application stores its configuration, log and any files needing persistency.
- `Port 5800`: for WebGUI
- `Port 5900`: for VNC client connection
- `$HOME`: This location contains files from your host that need to be accessible by the application.
- `$HOME/HandBrake/watch`: This is where videos to be automatically converted are located.
- `$HOME/HandBrake/output`: This is where automatically converted video files are written.

Browse to `http://your-host-ip:5800` to access the HandBrake GUI. Files from the host appear under the `/storage` folder in the container.

additional detailed info:
https://hub.docker.com/r/jlesage/handbrake#docker-container-for-handbrake
