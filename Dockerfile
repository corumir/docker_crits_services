#
# This Docker image encapsulates the Collaborative Research Into Threats (CRITs)
# malware and threat repository by The MITRE Corporation from https://crits.github.io/
#
# Please see the Readme.md within this repo to figure out the installation path
#

FROM ubuntu:14.04
MAINTAINER Matt Keen

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C

USER root

RUN apt-get -qq update && \
  apt-get install -y  software-properties-common && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
  apt-add-repository -y universe && \
  apt-get -qq update && apt-get install -y --fix-missing \
  build-essential \
  libjpeg-dev \
  curl \
  git \
  libevent-dev \
  libz-dev \
  libfuzzy-dev \
  libldap2-dev \
  libpcap-dev \
  libpcre3-dev \
  libsasl2-dev \
  libtool \
  libxml2-dev \
  libxslt1-dev \
  libyaml-dev \
  numactl \
  p7zip-full \
  python-dev \
  python-pip \
  swig \
  supervisor \
  wget \
  unrar-free \
  upx \
  vim \
  zip \
  libssl-dev \
  apache2 \
  python-chm \
  clamav \
  clamav-daemon \
  python-imaging \
  pyew \
  exiftool \
  antiword \
  poppler-utils \
  tcpdump \
  tshark \
  autoconf \
  libtool \
  python-nids \
  libapache2-mod-wsgi &&  \
  cp /etc/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf && \
  ldconfig

# Retrieve ssdeeep v.2.13 via wget, verify known good hash and install ssdeep
RUN cd /tmp && \
  wget -O ssdeep-2.13.tar.gz https://github.com/REMnux/docker/raw/master/dependencies/ssdeep-2.13.tar.gz && \
  sha256sum ssdeep-2.13.tar.gz > sha256sum.out && \
  sha256sum -c sha256sum.out && \
  tar vxzf ssdeep-2.13.tar.gz && \
  cd ssdeep-2.13/ && \
  ./configure && \
  make && \
  make install

# Setup CRITs
RUN bash -c 'mkdir -pv /data/{ssl/certs,ssl/private,log}' && \
  cd /data/ && \
  git clone https://github.com/crits/crits.git && \
  cd crits/ && \
  pip install -r requirements.txt

# Setup environment
RUN cd /data/crits/ && \
  touch /data/crits/logs/crits.log && \
  touch /data/log/startup.log && \
  ln -f -s /data/crits/logs/crits.log /data/log/crits.log && \
  chmod 664 /data/crits/logs/crits.log && \
  cp crits/config/database_example.py crits/config/database.py && \
  SC=$(cat /dev/urandom | LC_CTYPE=C tr -dc 'abcdefghijklmnopqrstuvwxyz0123456789!@#%^&*(-_=+)' | fold -w 50 | head -n 1) && \
  SE=$(echo ${SC} | sed -e 's/\\/\\\\/g' | sed -e 's/\//\\\//g' | sed -e 's/&/\\\&/g') && \
  sed -i -e "s/^\(SECRET_KEY = \).*$/\1\'${SE}\'/1" crits/config/database.py && \
  sed -i "s/localhost/mongo/" crits/config/database.py


# Setup Apache web server
RUN /etc/init.d/apache2 stop && \
  rm -rf /etc/apache2/sites-available/* && \
  cp /data/crits/extras/*.conf /etc/apache2 && \
  cp -r /data/crits/extras/sites-available /etc/apache2 && \
  rm /etc/apache2/sites-enabled/* && \
  ln -f -s /etc/apache2/sites-available/default-ssl /etc/apache2/sites-enabled/default-ssl && \
  mkdir -pv /etc/apache2/conf.d/i

# Setup self-signed cert and perform initial setup
RUN export "LANG=en_US.UTF-8" && \
  sed -i "/export\ LANG\=C/ s/C/en\_US\.UTF\-8/" /etc/apache2/envvars && \
  sed -i '$ i\\n0 * * * *       root    cd /data/crits/ && /usr/bin/python manage.py mapreduces\n0 * * * *       root    cd /data/crits/ && /usr/bin/python manage.py generate_notifications' /etc/crontab && \
  sed -i 's/^CustomLog \/var/CustomLog\ \/data/' /etc/apache2/apache2.conf && \
  sed -i 's/^ErrorLog\ \/var/ErrorLog\ \/data/' /etc/apache2/apache2.conf && \
  sed -i 's/\/var/\/data/' /etc/apache2/envvars && \
  sed -i 's/\ 443/\ 8443/' /etc/apache2/ports.conf && \
  sed -i 's/\/var/\/data/' /etc/apache2/sites-available/default && \
  sed -i 's/443/8443/' /etc/apache2/sites-available/default-ssl && \
  sed -i 's/\/etc/\/data/' /etc/apache2/sites-available/default-ssl && \
  sed -i 's/\/var/\/data/' /etc/apache2/sites-available/default-ssl

#Crits Services download
RUN cd /data && git clone https://github.com/crits/crits_services.git

#Yara + rules download/install
RUN curl -O https://codeload.github.com/plusvic/yara/tar.gz/v3.3.0 -s && \
  tar -xvf v3.3.0 && \
  cd yara-3.3.0 && \
  ./bootstrap.sh && \
  ./configure && \
  make && \
  make install && \
  cd /data && \
  git clone https://github.com/Yara-Rules/rules.git

#Add Crontabs
RUN echo "0 * * * * freshclam" > /etc/cron.d/freshclam && \
  echo "0 * * * * cd /data/rules && git pull https://github.com/Yara-Rules/rules.git" > /etc/cron.d/yara-rules


RUN cd /data &&  git clone --recursive git://github.com/MITRECND/htpy  && \
  cd htpy && \
  chmod +x setup.py && \
  ./setup.py build && \
  ./setup.py install

#Crits Services Dependencies

RUN pip install shodan \
  pydeep \
  pylzma \
  bitstring \
  pythonwhois \
  yara-python \
  stix-validator \
  pyClamd \
  pycrypto \
  numpy \
  pyimpfuzzy \
  mod_pywebsocket \
  pexpect \
  pefile \
  oletools \
  stix==1.2.0.1 \
  stix-ramrod==1.1.0 \
  libtaxii==1.1.109 \
  cybox==2.1.0.12 \
  PyInstaller \
  passivetotal \
  cbapi \
  mixbox \
  requests==2.11.1 \
  dnslib \
  pylibemu \
  yaraprocessor \
  pype32 \
  pytx

#CHOPSHOP INSTALL
RUN git clone https://github.com/MITRECND/pynids.git && \
  cd pynids && \
  chmod +x setup.py && \
  ./setup.py build && \
  ./setup.py install && \
  cd ../ && \
  echo '/opt/libemu/lib/' > /etc/ld.so.conf.d/libemu.conf && \
  ldconfig && \
  cd /data && \
  git clone https://github.com/MITRECND/chopshop.git &&  cd chopshop && \
  make install

COPY startup.sh /data/startup.sh

# STIX TAXII client fix
RUN sed -i "s/from stix\.utils import set_id_namespace/from mixbox\.idgen import set_id_namespace/" /data/crits_services/taxii_service/handlers.py

#PDFInfo
RUN cd /tmp && \
  curl -O http://didierstevens.com/files/software/pdf-parser_V0_6_6.zip && \
  curl -O http://didierstevens.com/files/software/make-pdf_V0_1_6.zip && \
  curl -O http://didierstevens.com/files/software/pdfid_v0_2_1.zip && \
  curl -O http://didierstevens.com/files/software/PDFTemplate.zip

#Hardening and script fix
RUN ldconfig && \
  rm -rf /tmp/* && \
  rm -rf /var/lib/apt/lists/* && \
  chmod +x /data/startup.sh

USER root
ENV HOME /home/root
ENV USER root
WORKDIR /data/crits
VOLUME ["/data/ssl"]


COPY crits_services_configuration.py /data/crits_services_configuration.py

# Expose ports 8443 from the container to the host
EXPOSE 8443

ENTRYPOINT cd /data && ./startup.sh && /bin/bash
