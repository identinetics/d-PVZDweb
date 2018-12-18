FROM intra/centos7_base
LABEL maintainer="Rainer Hörbe <r2h2@hoerbe.at>"

RUN yum -y update \
 && yum -y install java-1.8.0-openjdk-devel.x86_64 \
 && yum -y install gcc gcc-c++ sudo wget \
 && yum -y install libffi-devel libxslt-devel libxml2 libxml2-devel openssl-devel \
 && yum -y install openssh-server  \
 && yum -y install epel-release \
 && yum -y install nginx \
 && yum clean all
ENV JAVA_HOME=/etc/alternatives/java_sdk_1.8.0 \
    JDK_HOME=/etc/alternatives/java_sdk_1.8.0 \
    JRE_HOME=/etc/alternatives/java_sdk_1.8.0/jre

# install python3.6 (required minimum for this Django app)
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm \
    && yum -y install python36u python36u-setuptools python36u-devel python36u-pip \
 && yum clean all

# install application
COPY install/PVZDweb /opt/PVZDweb
RUN pip3.6 install virtualenv \
 && mkdir -p /opt/venv \
 && virtualenv --python=/usr/bin/python3.6 /opt/venv/pvzdweb \
 && touch /root/.profile \
 && printf "\nsource /opt/venv/pvzdweb/bin/activate\n" >> /root/.profile \
 && printf "\nsource /opt/PVZDweb/bin/setenv.sh " >> /root/.profile \
 && source /opt/venv/pvzdweb/bin/activate \
 && pip install Cython \
 && pip install -r /opt/PVZDweb/requirements.txt
COPY install/scripts/* /scripts/
RUN chmod +x /scripts/*

# install webapp
COPY install/PVZDweb/ /opt/PVZDweb/
RUN mkdir -p /var/log/webapp /var/log/pep \
 && chown -R $CONTAINERUSER:$CONTAINERGROUP /var/log/$CONTAINERUSER \
 && chmod 777 /run
# export static files to be served from nginx
VOLUME /opt/PVZDweb/database /var/log
EXPOSE 8080


# persist deployment-specific configuration in /ext/
RUN mkdir -p /config/etc/gunicorn \
             /config/etc/nginx \
             /config/etc/ssh \
             /config/home
COPY install/etc /config/etc
COPY install/PVZDweb/static_root /config/pvzdweb/static/static
VOLUME /config

# create container user owning database, git repo + web service processes
ARG CONTAINERUSER=pvzdapp
ARG CONTAINERUID=343039
ARG CONTAINERGROUP=repousers
ARG GID=$CONTAINERUID
RUN groupadd -g $GID $CONTAINERGROUP \
 && adduser --gid $GID --uid $CONTAINERUID --home-dir /var/lib/git  $CONTAINERUSER \
 && chmod 775 /var/lib/git
VOLUME /var/lib/git

# install tests
COPY install/tests/* /tests/
COPY install/testdata-setup /testdata-setup
RUN mkdir /testdata-run \
 && chown -R $CONTAINERUSER:$CONTAINERGROUP /testdata* /tests \
 && chmod +x /tests/*

# install postgres client (for ready-check)
RUN yum install -y postgresql \
 && yum clean all

# The file persistence_status is created in a persistenet volume once the data initialization is complete
ENV PERSISTENCE_STATUS=/config/etc/ssh/persistence_status
RUN touch $PERSISTENCE_STATUS

# Need to run as root because of sshd
# starting processes will drop off root privileges
CMD /scripts/start.sh
COPY install/opt/bin/manifest2.sh /opt/bin/manifest2.sh
RUN chmod +x /opt/bin/manifest2.sh \
 && mkdir -p $HOME/.config/pip \
 && printf "[global]\ndisable-pip-version-check = True\n" > $HOME/.config/pip/pip.conf
