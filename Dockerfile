################################################################################
# base system
################################################################################

FROM ubuntu:20.04 as system

#RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#mirror://mirrors.ubuntu.com/mirrors.txt#' /etc/apt/sources.list;

# Avoid prompts for time zone
ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Europe/Paris
# Fix issue with libGL on Windows
ENV LIBGL_ALWAYS_INDIRECT=1



# built-in packages
RUN apt-get update && apt-get upgrade -y && apt-get install apt-utils -y \
    && apt-get install -y --no-install-recommends software-properties-common curl apache2-utils \
    && apt-get update \
    && apt-get install -y --no-install-recommends --allow-unauthenticated \
        supervisor nginx sudo net-tools zenity xz-utils \
        dbus-x11 x11-utils alsa-utils \
        mesa-utils libgl1-mesa-dri wget

# install debs error if combine together
RUN apt-get update \
    && apt-get install -y --no-install-recommends --allow-unauthenticated \
        xvfb x11vnc \
        vim-tiny ttf-ubuntu-font-family ttf-wqy-zenhei

# Alternative VNC server
# RUN apt-get install -y tigervnc-scraping-server

# RUN apt-get update \
#     && apt-get install -y gpg-agent \
#     && curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
#     && (dpkg -i ./google-chrome-stable_current_amd64.deb || apt-get install -fy) \
#     && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add \
#     && rm google-chrome-stable_current_amd64.deb \
#     && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends --allow-unauthenticated \
        lxde gtk2-engines-murrine gnome-themes-standard gtk2-engines-pixbuf gtk2-engines-murrine arc-theme


RUN apt-get update && apt-get install -y python3 python3-tk gcc make cmake

# tini to fix subreap
ARG TINI_VERSION=v0.19.0
RUN wget https://github.com/krallin/tini/archive/v0.19.0.tar.gz \
 && tar zxf v0.19.0.tar.gz \
 && export CFLAGS="-DPR_SET_CHILD_SUBREAPER=36 -DPR_GET_CHILD_SUBREAPER=37"; \
    cd tini-0.19.0; cmake . && make && make install \
 && cd ..; rm -r tini-0.19.0 v0.19.0.tar.gz

#ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
#RUN chmod +x /bin/tini

# ffmpeg
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends --allow-unauthenticated \
#         ffmpeg \
#     && rm -rf /var/lib/apt/lists/* \
#     && mkdir /usr/local/ffmpeg \
#     && ln -s /usr/bin/ffmpeg /usr/local/ffmpeg/ffmpeg

# NextCloud
RUN apt-get -y update && apt-get install -y nextcloud-desktop

# Firefox
RUN apt-get -y update && apt-get install -y firefox libpci3

#XPAINT
RUN apt-get -y update && apt-get install -y xpaint

#Gpg agent
RUN apt-get -y update && apt -y install gpg-agent

#Sublime Text
RUN wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
RUN echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
RUN sudo apt -y update && sudo apt -y install sublime-text

#Beyond Compare
RUN wget https://www.scootersoftware.com/bcompare-4.4.4.27058_amd64.deb
RUN sudo apt -y update && sudo apt -y install ./bcompare-4.4.4.27058_amd64.deb
RUN sudo rm -Rf ./bcompare-4.4.4.27058_amd64.deb

#Codelite
RUN sudo apt-key adv --fetch-keys http://repos.codelite.org/CodeLite.asc
RUN sudo apt-add-repository 'deb https://repos.codelite.org/ubuntu/ focal universe'
RUN sudo apt -y update && sudo apt-get -y install codelite

#7zip
RUN sudo add-apt-repository universe
RUN sudo apt -y update
RUN sudo apt -y install p7zip-full p7zip-rar

#POSTGRESQL
RUN sudo apt -y update && sudo apt-get -y install postgresql-12
RUN curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
RUN sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
RUN sudo apt -y install pgadmin4
RUN sudo apt -y install pgadmin4-desktop
RUN sudo apt -y install pgadmin4-web 

#Sqlite3 and Sqlitebrowser
RUN sudo apt -y update && sudo apt-get -y install sqlite3
RUN sudo apt -y update && sudo apt-get -y install sqlitebrowser

#MongoDb 
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
RUN sudo apt-get -y update
RUN sudo apt-get install -y mongodb-org-shell

#Git 
RUN sudo apt -y update && sudo apt-get -y install git
RUN sudo apt -y update && sudo apt-get -y install git-gui

# Killsession app
COPY killsession/ /tmp/killsession
RUN cd /tmp/killsession; \
    gcc -o killsession killsession.c && \
    mv killsession /usr/local/bin && \
    chmod a=rx /usr/local/bin/killsession && \
    chmod a+s /usr/local/bin/killsession && \
    mv killsession.py /usr/local/bin/ && chmod a+x /usr/local/bin/killsession.py && \
    mkdir -p /usr/local/share/pixmaps && mv killsession.png /usr/local/share/pixmaps/ && \
    mv KillSession.desktop /usr/share/applications/ && chmod a+x /usr/share/applications/KillSession.desktop && \
    cd /tmp && rm -r killsession
    

# python library
COPY rootfs/usr/local/lib/web/backend/requirements.txt /tmp/
RUN apt-get update \
    && dpkg-query -W -f='${Package}\n' > /tmp/a.txt \
    && apt-get install -y python3-pip python3-dev build-essential \
    && pip3 install setuptools wheel && pip3 install -r /tmp/requirements.txt \
    && ln -s /usr/bin/python3 /usr/local/bin/python \
    && dpkg-query -W -f='${Package}\n' > /tmp/b.txt \
    && apt-get remove -y `diff --changed-group-format='%>' --unchanged-group-format='' /tmp/a.txt /tmp/b.txt | xargs` \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/* /tmp/a.txt /tmp/b.txt

RUN apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

################################################################################
# builder
################################################################################
FROM ubuntu:20.04 as builder

#RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#mirror://mirrors.ubuntu.com/mirrors.txt#' /etc/apt/sources.list;

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates gnupg patch

# nodejs
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install -y nodejs

# yarn
# Fix issue with libssl and docker on M1 chips
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
COPY yarnpkg_pubkey.gpg .
RUN cat yarnpkg_pubkey.gpg | apt-key add -  && rm yarnpkg_pubkey.gpg \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn

# build frontend
COPY web /src/web
RUN cd /src/web \
    && yarn upgrade \
    && yarn \
    && yarn build
RUN sed -i 's#app/locale/#novnc/app/locale/#' /src/web/dist/static/novnc/app/ui.js

RUN apt autoremove && apt autoclean

################################################################################
# merge
################################################################################
FROM system
LABEL maintainer="jack.crosnierdebellaistre@kikotey.com"

COPY --from=builder /src/web/dist/ /usr/local/lib/web/frontend/
COPY rootfs /
RUN ln -sf /usr/local/lib/web/frontend/static/websockify /usr/local/lib/web/frontend/static/novnc/utils/websockify && \
	chmod +x /usr/local/lib/web/frontend/static/websockify/run

EXPOSE 80
WORKDIR /root
ENV HOME=/home/ubuntu \
    SHELL=/bin/bash

HEALTHCHECK --interval=30s --timeout=5s CMD curl --fail http://127.0.0.1:6079/api/health
ENTRYPOINT ["/startup.sh"]
