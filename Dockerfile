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
    apt-get -y install locales \
               openssh-server \
    	       supervisor \
		       wget curl vim 
#               nginx-full

# Preparo locales
#
RUN locale-gen es_ES.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

# Preparo el timezone para Madrid
#
RUN echo "Europe/Madrid" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# Workaround para el Timezone, en vez de montar el fichero en modo read-only:
# 1) En el DOCKERFILE
RUN mkdir -p /config/tz && mv /etc/timezone /config/tz/ && ln -s /config/tz/timezone /etc/
# 2) En el Script entrypoint:
#     if [ -d '/config/tz' ]; then
#         dpkg-reconfigure -f noninteractive tzdata
#         echo "Hora actual: `date`"
#     fi
# 3) Al arrancar el contenedor, montar el volumen, a contiuación un ejemplo:
#     /Apps/data/tz:/config/tz
# 4) Localizar la configuración:
#     echo "Europe/Madrid" > /Apps/data/tz/timezone
 
# Permitir a root vía SSH
#
RUN echo 'root:docker2014' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir /var/run/sshd

# Creo el usuario con el que se ejecutará TVHeadEnd
RUN adduser --disabled-password --gecos '' tvheadend

# OPCCION A) - Entorno de desarrollo, compilar e instalar. 
#
# Nota: Esta opción ya no la utilizo pero la dejo aquí documentada, consiste en compilar
# directamente desde GitHub e instalar el ejecutable. La desventaja que tiene es que 
# genera un contenedor de más de 1GB, así que he optado por la OPCCIÓN B, que consiste
# en crear un fichero .DEB usando (https://github.com/LuisPalacios/base-tvheadend-deb)
# 
# A.1) Dependencias de TVHeadEnd
#RUN apt-get install -y git make dkms dpkg-dev \
#               debconf-utils software-properties-common \
#               build-essential debhelper libswscale-dev \		       
#               libavahi-client-dev libavcodec-dev \
#               libavfilter-dev libavformat-dev \
#               libavutil-dev libswscale-dev \
#               liburiparser1 liburiparser-dev \
#               debhelper libcurl4-gnutls-dev a52dec \		       
#               libssl-dev libiconv-hook1 libiconv-hook-dev \
#               librtmp-dev
#
# A.2) Descargar Tvheadend
#RUN git clone https://github.com/tvheadend/tvheadend.git /srv/tvheadend \
#    && cd /srv/tvheadend && git checkout master 
#
# A.2) Compilar e instalar
#  Directorio ejecutable:       /usr/local/bin
#  Directorio Datos Tvheadend:  /usr/local/share/tvheadend
#
#RUN cd /srv/tvheadend && ./configure --enable-libffmpeg_static --enable-kqueue --enable-bundle && make && make install
#
# A.3) Limpieza de temporales
#RUN rm -r /srv/tvheadend && apt-get purge -qq build-essential pkg-config git
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# OPCCION B) - Usar un paquete pre-compilado que ha sido creado con otro proyecto
# también disponible en GitHub: (https://github.com/LuisPalacios/base-tvheadend-deb)
#
# B.1) Instalar dependencias y las libav-tools
RUN apt-get install -y build-essential \
                       python-software-properties \
                       libavahi-client3 \
                       libavahi-common3 \
                       liburiparser1 \
                       software-properties-common \
                       libav-tools
                       
#
# ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ======
# EXPERIMENTAL: node-ffmpeg-mpegts-proxy-master
# ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ======
# Se trata de un proxy que utiliza avcon(ffmpeg) para convertir cualquier URL fuente
# en un stream MPEG-TS sobre HTTP. Estoy probándolo porque necesito forzar que se  
# resintonice el canal antes de solicitar el stream cuando solicito canales a 
# mi dreambox (con tarjeta de recepción de Satélite). En la Dreambox empleo el 
# software openspa 3.x y al solicitar un stream vía HTTP no siempre hace un ZapTo
# al canal, por lo que devuelve error. Necesito un sistema mediante el cual 
# pueda ejecutar un "pre-comando" antes de solicitar el streaming del video, he
# visto que este pequeño programa puede hacerlo (en teoría)
#

# Instalo nodejs 0.12 para poder instalar node-ffmpeg-mpegts-proxy
# Ver --> https://github.com/Jalle19/node-ffmpeg-mpegts-proxy
RUN curl -sL https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get install -y nodejs

# Instalo el proxy...
RUN mkdir -p /root/proxy && mkdir -p /root/proxy/libs && mkdir -p /root/proxy/support
ADD node-ffmpeg-mpegts-proxy/node-ffmpeg-mpegts-proxy.js /root/proxy/node-ffmpeg-mpegts-proxy.js
ADD node-ffmpeg-mpegts-proxy/package.json /root/proxy/package.json
ADD node-ffmpeg-mpegts-proxy/README.md /root/proxy/README.md
RUN chmod 755 /root/proxy/node-ffmpeg-mpegts-proxy.js
ADD node-ffmpeg-mpegts-proxy/libs /root/proxy/libs
ADD node-ffmpeg-mpegts-proxy/support /root/proxy/support
RUN cd /root/proxy && npm install

# B.1) Instalo el tvheadend precompilado
# Para crear el fichero .deb uso el proyecto https://github.com/LuisPalacios/base-tvheadend-deb
#
ENV debfile tvheadend_3.9.2497~g54533b3~precise_amd64.deb
#ENV debfile tvheadend_3.9.2662~ge4cdd3c~precise_amd64.deb
#ENV debfile tvheadend_3.9.2675~ge4f034a~precise_amd64.deb
ADD ${debfile} /tmp/${debfile}
RUN dpkg --install /tmp/${debfile}
RUN rm -f /tmp/${debfile}

# Añado el grabber de WebGrab+Plus. Notar que este script espera que 
# periódicamente se deje el fichero guide.xml en /config
ADD ./tv_grab_wg++ /usr/bin/tv_grab_wg++
RUN chmod 755 /usr/bin/tv_grab_wg++

# Puertos expuestos
#
EXPOSE 9981 9982

# Directorios expuestos
#
VOLUME /config /recordings

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
