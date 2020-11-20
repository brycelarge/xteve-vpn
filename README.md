# [xTeVe Docker VPN](https://xteve.de/)

## [Ubuntu base image used from linuxserver/docker-baseimage-ubuntu](https://github.com/linuxserver/docker-baseimage-ubuntu)

### Description

xTeVe is a M3U proxy server for Plex, Emby and any client and provider which supports the .TS and .M3U8 (HLS) streaming formats.

xTeVe emulates a SiliconDust HDHomeRun OTA tuner, which allows it to expose IPTV style channels to software, which would not normally support it.

OpenVPN has been added to this container to allow users to bypass shaping using a VPN connection. Hopefully this will help others as it has done so for me.

Credits to the programmers who did an amazing job on xTeVe, all I did was put this docker together for my needs.

## Usage

Here are some example snippets to help you get started creating a container.

### docker

```
docker create \
  --name=xteve \
  --net=host \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK_SET=022 `#optional` \
  -e XTEVE_DEBUG=0 `#optional` \
  -e XTEVE_BRANCH=master `#optional` \
  -p 34400:34400 `#required in bridge mode` \
  -v /path/to/config:/config \
  -v /path/to/tmp:/tmp/xteve \
  --restart unless-stopped \
  brycelarge/xteve-docker
```

## Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `--net=host` | Use Host Networking |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e XTEVE_DEBUG=0` | Set xTeVe debug level [ 0-3 ] Default: 0=OFF |
| `-e DEBUG=false` | Set container debug [ true or false ] Default: false |
| `-e XTEVE_BRANCH=master` | Set xTeVe git branch [ master|beta ] Default: master  |
| `-v /config` | xTeVe library location. |
| `-v /tmp/xteve` | xTeVe Location for the buffer files. |

## Umask for running applications

For all of our images we provide the ability to override the default umask settings for services started within the containers using the optional `-e UMASK=022` setting.
Keep in mind umask is not chmod it subtracts from permissions based on it's value it does not add. Please read up [here](https://en.wikipedia.org/wiki/Umask) before asking for support.

## Optional Parameters

If you want to run the container in bridge network mode (instead of the recommended host network mode) you will need to specify ports.

In bridge mode the docker container will assign it's own dockernet ip address (usually in the 172.17.x network).

```
  -p 34400:34400
```

## User / Group Identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id user` as below:

```
  $ id username
    uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)
```

## Application Setup

Webui can be found at `<your-ip>:34400/web`

## OpenVPN
OpenVPN is built in but disabled by default. Currently the container only supports PIA and Surfshark as providers.

Surfshark I have found to be the best for IPTV, less buffering but this could be different for you. I only tested with PIA and Surfshark as I had accounts with them, more can be added in the future. I have added the ability to use other OpenVPN config files so you are not limited to PIA and Surfshark

If you are running the VPN then use bridge mode otherwise you will have issues on your host.

#### List of OpenVPN parameters accepted by the container
| Parameter | Function |
| :----: | --- |
| `--net=bridge` | Use Bridge Networking |
| `--cap-add=NET_ADMIN` | Gives the container permission to make network changes |
| `-e OPENVPN_USERNAME=username` | Your VPN provider username |
| `-e OPENVPN_PASSWORD=password` | Your VPN provider password |
| `-e OPENVPN_CONFIG=Ca Toronto` | Configuration file for the VPN location |
| `-e OPENVPN_PROVIDER=PIA` | VPN Provider - SURFSHARK, PIA or CUSTOM |
| `-e OPENVPN_OPTIONS=--ping 60 --ping-restart 180` | Custom OpenVPN options (Leave blank if your unsure, this is just an example) |
| `-e OPENVPN_PROTOCOL=udp` | VPN Protocol udp or tcp |
| `-e CREATE_TUN_DEVICE=true` | Should the container create /dev/net or are you mounting it |
| `-e LOCAL_NETWORK=192.168.0.0/24` | Your local lan network |

#### PIA config files can be found here

https://www.privateinternetaccess.com/openvpn/openvpn.zip

#### SURFSHARk config files can be found here

https://my.surfshark.com/vpn/api/v1/server/configurations

#### If you wish to use your own custom ovpn file and provider, just place your ovpn file in a folder called openvpn inside your config directory. An openvpn folder will be created automatically on the first boot

Use the file name excluding the extension ".ovpn" for the value of OPENVPN_CONFIG parameter

#### Testing VPN throughput with speedtest-cli

Speedtest cli is installed in the container and can be used to test your throughput from within the container, more information can be found here.

https://www.speedtest.net/insights/blog/introducing-speedtest-cli/

You will need to ssh into the running container to run speedtest cli

```docker exec -ti xteve-vpn bash```

Or from host

```docker exec -t xteve-vpn sh -c 'speedtest --accept-license --accept-gdp'```

Enjoy!
