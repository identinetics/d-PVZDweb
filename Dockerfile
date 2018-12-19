FROM intra/centos7_base
LABEL maintainer="Rainer Hörbe <r2h2@hoerbe.at>"

RUN yum -y update \
 && yum -y install java-1.8.0-openjdk-devel.x86_64 \
 && yum -y install gcc gcc-c++ sudo wget \
 && yum -y install libffi-devel libxslt-devel libxml2 libxml2-devel openssl-devel \
 && yum -y install openldap-devel \
 && yum -y install epel-release \
 && yum -y install nginx \
 && yum clean all
ENV JAVA_HOME=/etc/alternatives/java_sdk_1.8.0 \
    JDK_HOME=/etc/alternatives/java_sdk_1.8.0 \
    JRE_HOME=/etc/alternatives/java_sdk_1.8.0/jre

# install python3.6 (required minimum for this Django app)
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm \
 && yum -y install python36u python36u-setuptools python36u-devel python36u-pip \
 && ln -sf /usr/bin/python3.6 /usr/bin/python3 \
 && ln -sf /usr/bin/pip3.6 /usr/bin/pip3 \
 && yum clean all

# install postgres client (for ready-check)
RUN yum install -y postgresql \
 && yum clean all

# install application
COPY install/PVZDweb /opt/PVZDweb
RUN pip3.6 install virtualenv \
 && mkdir -p /opt/venv \
 && virtualenv --python=/usr/bin/python3.6 /opt/venv/pvzdweb \
 && source /opt/venv/pvzdweb/bin/activate \
 && pip install Cython \
 && pip install -r /opt/PVZDweb/requirements.txt
COPY install/scripts/* /scripts/
COPY install/etc/profile.d/pvzdweb.sh /etc/profile.d/pvzdweb.sh
RUN chmod +x /scripts/*
VOLUME /opt/PVZDweb/pvzdweb

#RUN mkdir -p /var/log/webapp /var/log/pep \
# && chown -R $CONTAINERUSER:$CONTAINERGROUP /var/log/$CONTAINERUSER \
# && chmod 777 /run
# VOLUME /opt/PVZDweb/database
VOLUME /var/log
EXPOSE 8080


# persist deployment-specific configuration
RUN mkdir -p /config/etc/gunicorn \
             /config/etc/nginx
COPY install/etc /config/etc
COPY install/PVZDweb/static_root /config/pvzdweb/static/static
VOLUME /config

# install tests
COPY install/tests/* /tests/
COPY install/testdata-setup /testdata-setup
RUN mkdir /testdata-run \
 && chown -R $CONTAINERUSER:$CONTAINERGROUP /testdata* /tests \
 && chmod +x /tests/*

# build number generation
COPY install/opt/bin/manifest2.sh /opt/bin/manifest2.sh
RUN chmod +x /opt/bin/manifest2.sh \
 && mkdir -p $HOME/.config/pip \
 && printf "[global]\ndisable-pip-version-check = True\n" > $HOME/.config/pip/pip.conf

SHELL ["/bin/bash", "-l", "-c"]