FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update 
RUN apt-get -y upgrade

RUN apt-get install -y \
    xfce4 \
    xfce4-clipman-plugin \
    xfce4-cpugraph-plugin \
    xfce4-netload-plugin \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-terminal \
    xfce4-xkb-plugin \
    wget \
    curl \
    neofetch

RUN apt-get install -y \
    dbus-x11 

RUN apt-get install -y \
    sudo \
    wget \
    xorgxrdp \
    xrdp && \
    apt remove -y light-locker xscreensaver && \
    apt autoremove -y && \
    rm -rf /var/cache/apt /var/lib/apt/lists

RUN apt-get update && apt-get install -y python3-pip

COPY ./build.sh /usr/bin/
RUN mv /usr/bin/build.sh /usr/bin/run.sh
RUN chmod +x /usr/bin/run.sh


# Docker config
EXPOSE 3389
ENTRYPOINT ["/usr/bin/run.sh"]
