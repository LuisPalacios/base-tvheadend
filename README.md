# Introducción

<p align="justify">Tvheadend es un DVR (Digital Video Recorder) y servidor de streaming de TV que soporta todo tipo de fuentes (físicas) DVB-C, DVB-T(2), DVB-S(2), ATSC y además fuentes "IP", conocidas como IP Televisión o IPTV (que usan los protocolos UDP o HTTP).</p>

<p align="justify">Para el caso de las fuentes físicas quizá no tiene demasiado sentido un contenedor Docker debido al vínculo con el interfaz físico, pero sí lo tiene para el caso de usar solo fuentes IPTV.</p>

<p align="justify">En este repositorio tenemos por tanto un *contenedor Docker* para ejecutar TVHeadEnd principalmente enfocado en dar servicio a canales IPTV (y su EPG). Está automatizado en el Registry Hub de Docker  [luispa/base-tvheadend](https://registry.hub.docker.com/u/luispa/base-tvheadend/) conectado con el proyecto en [GitHub base-tvheadend](https://github.com/LuisPalacios/base-tvheadend)</p>

<p align="justify">Puede que te interesen otros casos de uso que he preparado con docker, si es así, en este [apunte técnico sobre servicios en contenedores Docker](http://www.luispa.com/?p=172) 
encontrarás varios.</p> 


## Ficheros

* **Dockerfile**: Necesario para crear la base de servicio.
* **do.sh**: Script que se ejecuta al arrancar el contenedor.


# Gestión del contenedor

## Construcción

Si deseas construir tú mismo este contenedor primero necesitas clonarlo desde Github para
poder trabajar con él directamente

    ~ $ clone https://github.com/LuisPalacios/docker-tvheadend.git

Luego ya puedes modificarlo y/o crear la imagen localmente con el siguiente comando

    $ docker build -t luispa/base-tvheadend ./


## Ejecución

<p align="justify">Cuando ejecutes el contenedor verás que la versión de TVHeadEnd instalada es la 3.9+ 
(inestable), es decir, lo último disponible en su repositorio en [GitHub: tvheadend/tvheadend](https://github.com/tvheadend/tvheadend).</p>

Opcional y previo a la ejecución, puedes pre-descargarte desde el registry la imagen.

    ~ $ docker pull luispa/base-tvheadend


Para ejecutar manualmente a continuación tienes un ejemplo:
                                         
    docker run -p 9981:9981 -p 9982:9982 -v /Users/luis/Apps/data/tvheadend/config:/config  \
                                         -v /Users/luis/Apps/data/tvheadend/recordings:/recordings \
                                         luispa/base-tvheadend supervisord -n -c /etc/supervisor/supervisord.conf
                                         

<p align="justify">Si analizas el fichero do.sh verás que el comando que se ejecuta internamente a través de supervisord es el siguiente: </p>

	/usr/local/bin/tvheadend -C -u tvheadend -g tvheadend -c /config


<p align="justify">Los directorios locales (en el Host) que tienes que vincular son el directorio de datos (/config) de tvheadend y el directorio donde dejará las grabaciones (/recordings). Si vemos el ejemplo anterior, en mi caso defino que los directorios siguientes son los que utilizará el programa para dicho fin: </p>

	/config  	-->  Vinculado a /Users/luis/Apps/data/tvheadend/config en mi Host
	/recordings	-->  Vinculado a /Users/luis/Apps/data/tvheadend/recordings en mi Host

<p align="justify">El directorio "config" puede estar vacío y la primera vez se creará toda la subestructura y tendrás que configurar desde cero usando el interfaz Web. Por otro lado, si deseas migrar una instalación existente solo tienes que copiar todo el contenido del directorio de datos de la instalación antigua a este directorio (en mi ejemplo /Users/luis.../config)</p>

<p align="justify">La seguridad que trae por defecto es inexistente, recomiendo que crees un usuario nada más empezar a administrar y restrinjas el acceso del usuario por defecto. </p>


## Uso de TVHeadEnd

<p align="justify">A partir de aquí ya puedes entrar a configurar y usar TVHeadEnd. Todo el proceso de configuración, monitorización (e incluso un cliente para ver los canales) se realiza desde el interfaz Web, conectando con el puerto 9981 del servidor:</p>

    http://ip_del_host_contenedor:9981

<p align="justify">Tienes toda la documentación en la página del [proyecto Tvheadend](https://tvheadend.org/), así que aquí solo dejo una pequeña introducción: El programa presentanos un interfaz Web para poder configurar, en la versión 3.9+ tienes que crear los MUX's, después que se descubran los SERVICIOS, después crear los CANALES y fuentes EPG y finalmente conectar todo entre sí, es decir vincular cada canal con el Servicio y con el EPG. </p>

<p align="justify">¿Qué es un MUX? pues viene del concepto de Multiplexor que se maneja en las emisiones terrestres o satélite, donde dentro de una frecuencia agrupan varios canales multiplexados. Esa es la razón por la que lo primero a añadir es el MUX, para que lo "escanee" y descubra los servicios que lleva dentro. El paso a repetir por cana canal es crearlo como un objeto independiente y asociarle el servicio y EPG que corresponda. </p>


