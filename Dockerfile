#
# Squid container by Luispa, Feb 2015
# -----------------------------------------------------
#

# Desde donde parto...
#
FROM debian:jessie

#
MAINTAINER Luis Palacios <luis@luispa.com>

# Pido que el frontend de Debian no sea interactivo
ENV DEBIAN_FRONTEND noninteractive

# Actualizo e instalo
RUN apt-get update && \
    apt-get -y install locales        \
    	       	       openssh-server \
    	       	       supervisor     \
		       wget 	      \
		       curl

# Preparo locales
#
RUN locale-gen es_ES.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# Preparo el timezone para Madrid
#
RUN echo "Europe/Madrid" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# 
# Dependencias de TVHeadEnd
RUN apt-get install -y wget git curl make dkms dpkg-dev \
    	    	       debconf-utils software-properties-common \
		       linux-headers-3.16.0-4-all-amd64 \
		       build-essential debhelper libswscale-dev \
		       libavahi-client-dev libavformat-dev \
		       libavcodec-dev liburiparser-dev \
		       libssl-dev libiconv-hook1 libiconv-hook-dev

# Permitir a root vía SSH
#
RUN echo 'root:docker2014' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir /var/run/sshd


# TVHeadEnd, descarga
RUN git clone https://github.com/tvheadend/tvheadend.git /srv/tvheadend \
    && cd /srv/tvheadend && git checkout master 

# TVHeadEnd, compilo e instalo
#  Directorio ejecutable:       /usr/local/bin
#  Directorio Datos Tvheadend:  /usr/local/share/tvheadend
#
RUN cd /srv/tvheadend && ./configure --libffmpeg_static && make && make install

# Limpieza de ficheros temporales
RUN rm -r /srv/tvheadend && apt-get purge -qq build-essential pkg-config git
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Creo el usuario con el que se ejecutará TVHeadEnd
RUN adduser --disabled-password --gecos '' tvheadend


# Puertos expuestos
#
EXPOSE 9981 9982

# Directorios expuestos
#
VOLUME /config /recordings /data

#-----------------------------------------------------------------------------------

# Ejecutar siempre al arrancar el contenedor este script
#
ADD do.sh /do.sh
RUN chmod +x /do.sh
ENTRYPOINT ["/do.sh"]

#
# Si no se especifica nada se ejecutará lo siguiente: 
#
CMD ["/usr/bin/supervisord", "-n -c /etc/supervisor/supervisord.conf"]
