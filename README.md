# Docker PulseAudio Example
An example of a PulseAudio app working within a Docker container using the hosts sound system

[Docker Hub](https://hub.docker.com/r/thebiggerguy/docker-pulseaudio-example/)

## Building
```bash
./build.sh
```

## Running
```bash
./host_runner.sh
```

## Explanation
Getting a PulseAudio app to work within a Docker container is harder than it looks. This example is designed to produce the smallest working configuration that can be used in your own containers.

To be clear this is designed so the app within the Docker container does not run a PulseAudio server. Instead the app connects as a client directly to the hosts PulseAudio server and uses it's configuration/devices to output the sound. This is achieved by mapping the UNIX socket used by PulseAudio in the host into the container and configuring its use.

Most of the complexity of the Dockerfile is setting up a non root user. This is kept in the example as near all uses of this **should** not be running the app as root.

## Common / Known Issues

### OSX/Darwin

install pulseaudio
```bash
brew install pulseaudio
```

if doing X11 Gui in OSX
```bash
 brew cask install xquartz
```

edit `/usr/local/Cellar/pulseaudio/11.1/etc/pulse/default.pa`
```
# Change these to enabled
load-module module-esound-protocol-tcp
load-module module-native-protocol-tcp

# Make sure to disable idle timeouts since x11 make take some time
### Automatically suspend sinks/sources that become idle for too long
#load-module module-suspend-on-idle
```

If you want GUI in OSX using docker, then each container image
has to be built with pulseaudio as found in theis repo, then
whenever you run docker:
```bash
### Get X11 Display
IP=$(ifconfig|grep -E inet.*broad|awk '{ print $2; }')	

open -a XQuartz &
p=0;for port in $(seq 0 10);do echo "Check :$((6000+$p)) (:$p)";  nc -w0 127.0.0.1 $((6000+$p)) && export DISPLAY="$IP:$p"; let p=p+1;  done;
/usr/X11/bin/xhost + $IP

### run the container and point it to locally running pulseuadio service
### which should be the same host as X11, if not adjust accordingly. 
### also, sorry I dont have public image of firefox with pulse. soon.
docker run -d \
		-e PULSE_SERVER=tcp:${IP}:4713 \
	  -e PULSE_COOKIE=/run/pulse/cookie \
	  -v ~/.config/pulse/cookie:/run/pulse/cookie \
		-v "${HOME}/.firefox/cache:/root/.cache/mozilla" \
		-v "${HOME}/.firefox/mozilla:/root/.mozilla" \
		-v "${HOME}/Downloads:/root/Downloads" \
		-v "${HOME}/Pictures:/root/Pictures" \
		-e "DISPLAY=${DISPLAY}" \
		-e GDK_SCALE \
		-e GDK_DPI_SCALE \
		--name firefox \
		${DOCKER_REPO_PREFIX}/firefox "$@"
```

### SHM
`shm_open() failed: No such file or directory` Is caused by PulseAudio trying to use Shared Memory (`/dev/shm` or `/run/shm`) as a performance enhancement. In this example SHM is disabled to prevent this issue.

### TCP / Avahi
This would be another method to configure PulseAudio by enabling the host server to open an TCP server and the container connecting to it. This was avoided as it:
 * Unnecessarily causes the container to be networked to the host.
 * Requires additional PulseAudio modules and changed configuration on the host.
 * Is less performant.
