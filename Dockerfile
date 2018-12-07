FROM intra/centos7_base
LABEL maintainer="Rainer Hörbe <r2h2@hoerbe.at>"

RUN yum -y update \
 && yum -y install java-1.8.0-openjdk-devel.x86_64 \
 && yum -y install gcc gcc-c++ sudo wget \
 && yum -y install libffi-devel libxslt-devel libxml2 libxml2-devel openssl-devel \
 && yum -y install openssh-server \
 && yum clean all
ENV JAVA_HOME=/etc/alternatives/java_sdk_1.8.0 \
    JDK_HOME=/etc/alternatives/java_sdk_1.8.0 \
    JRE_HOME=/etc/alternatives/java_sdk_1.8.0/jre

# install python3.5 (required minimum for this Django app)
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm \
    && yum -y install python35u python35u-setuptools python35u-devel python35u-pip \
 && yum clean all

# install application
# ====================================
COPY install/PVZDweb /opt/PVZDweb
RUN pip3.5 install virtualenv \
 && mkdir -p /opt/venv \
 && virtualenv --python=/usr/bin/python3.5 /opt/venv/pvzdweb \
 && printf "\nsource /opt/venv/pvzdweb/bin/activate\n" >> $HOME/.profile \
 && source /opt/venv/pvzdweb/bin/activate \
 && pip install Cython \
 && pip install -r /opt/PVZDweb/requirements.txt
COPY install/scripts/* /scripts/
RUN chmod +x /scripts/*

# create container user owning git repo + web service processes
ARG CONTAINERUSER=pvzdfe
ARG CONTAINERUID=343039
ARG CONTAINERGROUP=repousers
ARG GID=$CONTAINERUID
RUN groupadd -g $GID $CONTAINERGROUP \
 && adduser --gid $GID --uid $CONTAINERUID --home-dir /var/lib/git  $CONTAINERUSER \
 && chmod 775 /var/lib/git
VOLUME /var/lib/git

#create backend user (ssh key authorization to be added at runtime)
RUN adduser --gid $GID --shell /usr/bin/git-shell backend \
 && mkdir /home/backend/.ssh /home/backend/git-shell-commands \
 && chown backend /home/backend/.ssh \
 && chmod 755 /home/backend
COPY install/scripts/no-interactive-login /home/backend/git-shell-commands/no-interactive-login
RUN chmod +x /home/backend/git-shell-commands/no-interactive-login
VOLUME /home/backend

#install tests
COPY install/tests/* /tests/
COPY install/testdata-setup /testdata-setup
COPY install_99/dot_ssh/backend_id_ecdsa.pub /testdata-setup/root/dot_ssh/authorized_keys
RUN mkdir /testdata-run \
 && chown -R $CONTAINERUSER:$CONTAINERGROUP /testdata* /tests \
 && chmod +x /tests/*

# install webapp
COPY install/PVZDweb/ /opt/PVZDweb/
RUN mkdir -p /var/log/$CONTAINERUSER \
 && chown -R $CONTAINERUSER:$CONTAINERGROUP /var/log/$CONTAINERUSER \
 && chmod 777 /run
# export static files to be served from nginx
VOLUME /opt/PVZDweb/static_root \
       /opt/PVZDweb/database
# Port for nginx proxy
EXPOSE 8080


# Prepare git ssh service (postpone key generation to run time!)
RUN rm -f /etc/ssh/ssh_host_*_key \
 && mkdir -p /opt/etc/ssh \
 && cp -p /etc/ssh/sshd_config /opt/etc/ssh/sshd_config \
 && echo 'GSSAPIAuthentication no' >> /opt/etc/ssh/sshd_config \
 && echo 'useDNS no' >> /opt/etc/ssh/sshd_config \
 && sed -i -e 's/#Port 22/Port 2022/' /opt/etc/ssh/sshd_config \
 && sed -i -e 's/^HostKey \/etc\/ssh\/ssh_host_/HostKey \/opt\/etc\/ssh\/ssh_host_/' /opt/etc/ssh/sshd_config
# The file persistence_status is created in a persistenet volume once the data initialization is complete
ENV PERSISTENCE_STATUS=/opt/etc/ssh/persistence_status
RUN touch $PERSISTENCE_STATUS
VOLUME /opt/etc/ssh
EXPOSE 2022

# Need to run as root because of sshd
# starting processes will drop off root privileges
CMD /scripts/start.sh
RUN mkdir -p $HOME/.config/pip \
 && printf "[global]\ndisable-pip-version-check = True\n" > $HOME/.config/pip/pip.conf
COPY install/opt/bin/manifest2.sh /opt/bin/manifest2.sh