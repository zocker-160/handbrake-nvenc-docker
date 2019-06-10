# docker-handbrake

# Fork of jlesage/handbrake, adds NVENC, removes Intel Quick Sync

Handbrake GUI with Web browser and VNC access. Supports NVENC encoding

Requires
```
 --runtime=nvidia
-e NVIDIA_DRIVER_CAPABILITIES=all
```
additional requirements:
https://hub.docker.com/r/jlesage/handbrake#docker-container-for-handbrake
