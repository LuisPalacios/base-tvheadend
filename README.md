# Introducción

Tvheadend es un DVR (Digital Video Recorder) y servidor de streaming de TV que soporta todo tipo de fuentes, por ejemplo las que necesitan un interfaz o receptor DVB-C, DVB-T(2), DVB-S(2), ATSC y por otro lado las fuentes "IP", conocidas como IP Televisión o IPTV (que usan los protocolos UDP o HTTP) y no necesitan de ningún receptor físico.

Para el caso de las fuentes que necesitan un dispositivo o interfaz para la recepción quizá no tiene demasiado sentido un contenedor Docker debido al vínculo con dicho interfaz, pero sí lo tiene para el caso de usar solo fuentes IPTV.

En este repositorio tenemos por tanto un *contenedor Docker* para ejecutar TVHeadEnd principalmente enfocado en dar servicio a canales IPTV (y su EPG).

*  Automatizado en el Registry Hub de Docker  [luispa/base-tvheadend](https://registry.hub.docker.com/u/luispa/base-tvheadend/) 
*  Conectado con el proyecto en [GitHub base-tvheadend](https://github.com/LuisPalacios/base-tvheadend)
*  Servicio FIG para ejecutarlo en [GitHub servicio-tvheadend](https://github.com/LuisPalacios/servicio-tvheadend)

Si te interesan otros casos de uso consulta este [apunte técnico sobre servicios en contenedores Docker](http://www.luispa.com/?p=172).


## Ficheros

* **Dockerfile**: Necesario para crear la base de servicio.
* **do.sh**: Script que se ejecuta al arrancar el contenedor.


# Gestión del contenedor

## Clonar y manipular

Si deseas construir tú mismo este contenedor primero necesitas clonarlo desde Github para poder trabajar con él directamente:

    ~ $ clone https://github.com/LuisPalacios/docker-tvheadend.git

Luego puedes modificarlo y/o crear la imagen localmente con el siguiente comando

    $ docker build -t luispa/base-tvheadend ./


## Usarlo directamente

Si por otro lado lo que quieres es simplemente usar este contenedor solo tienes que instalarte Docker y seguir las instrucciones de esta sección. Nota que cuando ejecutes el contenedor verás que la versión de TVHeadEnd instalada es la 3.9+ (inestable), es decir, lo último disponible en su repositorio.

* [GitHub: tvheadend/tvheadend](https://github.com/tvheadend/tvheadend)

Empezamos. Este paso es opcional y previo a la ejecución, te permite pre-descargarte mi imagen desde el registry de Docker.

    ~ $ docker pull luispa/base-tvheadend


El paso importante es el siguiente, y tenemos varias formas de hacerlo, consiste en "Ejecutar" el contenedor y por tanto ejecutar Tvheadend. Elije entre una de las siguientes: 

### Ejecutar manualmente 

Este sería un ejemplo de ejecución manual: 
                                         
    docker run -p 9981:9981 -p 9982:9982 \
               -v /Apps/tvheadend/config:/config  \
               -v /Apps/tvheadend/recordings:/recordings \
               luispa/base-tvheadend supervisord -n -c /etc/supervisor/supervisord.conf
                                         

### Ejecutar con FIG

Otra opción más normal es ejecutar en segundo plano y para ello recomiendo usar FIG, necesitas el fichero fig.yml que he dejado en el repositorio [luispa/servicio-tvheadend](https://github.com/LuisPalacios/servicio-tvheadend)


### Detalle de la ejecución

Si analizas el fichero do.sh verás que el comando que se ejecuta internamente a través de supervisord es el siguiente:

	/usr/local/bin/tvheadend -C -u tvheadend -g tvheadend -c /config


Los directorios locales (en el Host) que tienes que vincular son el directorio de datos (/config) de tvheadend y el directorio donde dejará las grabaciones (/recordings). Si vemos el ejemplo anterior, en mi caso defino que los directorios siguientes son los que utilizará el programa para dicho fin:

	/config  	-->  Vinculado a /Users/luis/Apps/data/tvheadend/config en mi Host
	/recordings	-->  Vinculado a /Users/luis/Apps/data/tvheadend/recordings en mi Host

El directorio "config" puede estar vacío y la primera vez se creará toda la subestructura y tendrás que configurar desde cero usando el interfaz Web. Por otro lado, si deseas migrar una instalación existente solo tienes que copiar todo el contenido del directorio de datos de la instalación antigua a este directorio (en mi ejemplo /Users/luis.../config).

Otro vínculo que realizo es el del script "tv_grab_wg++", se trata del grabber que utilizao para bajarme la programación (EPG) desde internet. Empleo el programa WebGrapg+Plus y lo ejecuto en el Host, por lo tanto necesito acceder a dicho script desde el contenedor. 

    /usr/bin/tv_grab_wg++  -->  Script bash que uso para pasarle a tvheadend el EPG
    
Por último, la seguridad que trae por defecto es inexistente, recomiendo que crees un usuario nada más empezar a administrar y restrinjas el acceso del usuario por defecto.


## Uso de TVHeadEnd

A partir de aquí ya puedes entrar a configurar y usar TVHeadEnd. Todo el proceso de configuración, monitorización (e incluso un cliente para ver los canales) se realiza desde el interfaz Web, conectando con el puerto 9981 del servidor:

    http://ip_del_host_contenedor:9981

* Tienes toda la documentación en: Página del [proyecto Tvheadend](https://tvheadend.org/)

Una pequeña introducción: En la versión 3.9+ tienes que crear los MUX's, después que se descubran los SERVICIOS, después crear los CANALES y fuentes EPG y finalmente conectar todo entre sí, es decir vincular cada canal con el Servicio y con el EPG.

¿Qué es un MUX? pues viene del concepto de Multiplexor en las emisiones terrestres o por satélite, donde dentro de una frecuencia agrupan varios canales multiplexados. Esa es la razón por la que lo primero a añadir es el MUX, para que lo "escanee" y descubra los servicios que lleva dentro. El paso a repetir por cana canal es crearlo como un objeto independiente y asociarle el servicio y EPG que corresponda.


