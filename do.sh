#!/bin/bash
#
# Punto de entrada para el servicio tvheadend
#
# Activar el debug de este script:
# set -eux
#

##################################################################
#
# main
#
##################################################################

# Averiguar si necesito configurar TVHeadEnd por primera vez
#
CONFIG_DONE="/.config_tvheadend_done"
NECESITA_PRIMER_CONFIG="si"
if [ -f ${CONFIG_DONE} ] ; then
    NECESITA_PRIMER_CONFIG="no"
fi

##################################################################
#
# PREPARAR timezone
#
##################################################################
# Workaround para el Timezone, en vez de montar el fichero en modo read-only:
# 1) En el DOCKERFILE
#    RUN mkdir -p /config/tz && mv /etc/timezone /config/tz/ && ln -s /config/tz/timezone /etc/
# 2) En el Script entrypoint:
if [ -d '/config/tz' ]; then
    dpkg-reconfigure -f noninteractive tzdata
    echo "Hora actual: `date`"
fi
# 3) Al arrancar el contenedor, montar el volumen, a contiuación un ejemplo:
#     /Apps/data/tz:/config/tz
# 4) Localizar la configuración:
#     echo "Europe/Madrid" > /Apps/data/tz/timezone

# Crear el directorio para los iconos
mkdir -p /config/picons
chmod 777 /config/picons

# Cambiar los permisos para el directorio config
chown -R tvheadend:tvheadend /config


##################################################################
#
# PREPARAR EL CONTAINER POR PRIMERA VEZ
#
##################################################################

# Necesito configurar por primera vez?
#
if [ ${NECESITA_PRIMER_CONFIG} = "si" ] ; then

	############
	#
	# Supervisor
	# 
	############
	cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[unix_http_server]
file=/var/run/supervisor.sock                   ; path al socket

[inet_http_server]
port = 0.0.0.0:9001                             ; permitir conectar con supervisord desde un browser

[supervisord]
logfile=/var/log/supervisor/supervisord.log     ; ficheor de log del supervisord 
logfile_maxbytes=50MB 				; maximum size of logfile before rotation
logfile_backups=10 				; number of backed up logfiles
loglevel=error 					; info, debug, warn, trace
pidfile=/var/run/supervisord.pid 		; pidfile location
minfds=1024 					; number of startup file descriptors
minprocs=200 					; number of process descriptors
user=root 			            	; default user
childlogdir=/var/log/supervisor/ 		; where child log files will live

nodaemon=false 					; run supervisord as a daemon when debugging
;nodaemon=true 				        ; run supervisord interactively (production)
 
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
 
[supervisorctl]
serverurl=unix:///var/run/supervisor.sock	; use a unix:// URL for a unix socket 

[program:tvheadend]
command = /usr/bin/tvheadend -C -u tvheadend -g tvheadend -c /config

EOF

	############
    #
    # Creo el fichero de control para que el resto de 
    # ejecuciones no realice la primera configuración
    #
	############
    > ${CONFIG_DONE}

fi

##################################################################
#
# EJECUCIÓN DEL COMANDO SOLICITADO
#
##################################################################
#
exec "$@"
