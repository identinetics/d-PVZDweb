FROM intra/centos7_py36_base

RUN yum -y update \
 && yum -y install java-1.8.0-openjdk-devel.x86_64 \
 && yum -y install gcc gcc-c++ net-tools sudo wget \
 && yum -y install libffi-devel libxslt-devel libxml2 libxml2-devel openssl-devel \
 && yum -y install openldap-devel python36u-devel \
 && yum -y install epel-release \
 && yum -y install nginx \
 && yum clean all
ENV JAVA_HOME=/etc/alternatives/java_sdk_1.8.0 \
    JDK_HOME=/etc/alternatives/java_sdk_1.8.0 \
    JRE_HOME=/etc/alternatives/java_sdk_1.8.0/jre

# install postgres client (for ready-check)
RUN yum install -y postgresql \
 && yum clean all

RUN yum install -y postgresql \
 && yum clean all

# install web application
COPY install/PVZDweb /opt/PVZDweb
RUN pip3.6 install virtualenv \
 && mkdir -p /opt/venv \
 && virtualenv --python=/usr/bin/python3.6 /opt/venv/pvzdweb \
 && source /opt/venv/pvzdweb/bin/activate \
 && pip install Cython \
 && pip install -r /opt/PVZDweb/requirements.txt
COPY install/etc/profile.d/pvzdweb.sh /etc/profile.d/pvzdweb.sh

# install sig proxy
COPY install/seclay_xmlsig_proxy /opt/seclay_xmlsig_proxy
RUN virtualenv --python=/usr/bin/python3.6 /opt/venv/sigproxy \
 && source /opt/venv/sigproxy/bin/activate \
 && pip install -r /opt/seclay_xmlsig_proxy/requirements.txt \
 && mkdir -p /var/log/sigproxy/

# install custom config and scripts
COPY install/opt /opt
RUN chmod +x /opt/bin/*

# install tests
COPY install/tests/* /tests/
COPY install/testdata-setup /testdata-setup
RUN mkdir /testdata-run \
 && chown -R $CONTAINERUSER:$CONTAINERGROUP /testdata* /tests \
 && chmod +x /tests/*

# dcshell build number generation
COPY install/opt/bin/manifest2.sh /opt/bin/manifest2.sh
RUN chmod +x /opt/bin/manifest2.sh \
 && mkdir -p $HOME/.config/pip \
 && printf "[global]\ndisable-pip-version-check = True\n" > $HOME/.config/pip/pip.conf

ENV APPHOME /opt/PVZDweb
VOLUME /opt/etc \
       /opt/PVZDweb/pvzdweb \
       /var/log
EXPOSE 8080
SHELL ["/bin/bash", "-l", "-c"]