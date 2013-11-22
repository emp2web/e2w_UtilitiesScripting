#!/bin/bash

#############################################

# Nombre: Generador de Backups: 2013-11-21 
# @author: emp2web
# 
#   
# Este escript genera un backup de la base de datos inidicada
# en 2 formatos diferentes, adicional comprime todo el codigo del sistema 
# luego genera un nuevo archivo con los 2 backups y los envia a un nuevo
# servidor. 
# 
# Por ultimo envia un corre informando de lo generado y el link de descarga
# 
# Se debe tner instalado los paqetes para el envio de email
# apt-get install mailutils
# 
# Configuracion para el envio sin clave
# Se debe generar una llave publica en nuestro servidor con
# ssh-keygen -t rsa
# 
# luego podemos observar con 
# cat ~/.ssh/id_rsa.pub
# 
# La seleccionamos, la copiamos y la pegamos en el servidor remoto en el archivo
# ~/.ssh/authorized_keys

###########################################



BACKUP_DIR_REMOTO=ip:/path externo
BD=mm


# Varibales Generales
FECHA=`date +%Y-%m-%d`
CODIGO=`date +%Y%m%d`
POS="$1"
BACKUP_DIR=/tmp
CARPETAI=$BACKUP_DIR/$BD
CARPETAF=$CARPETAI/$FECHA
CARPETA=$CARPETAI/$FECHA/$1

# Varibales del codigo
PATHCODIGO=/var/www/mm/ # Ubicacion del codigo
SISTEMA='nombre del sistema'

# Varibales de correo
DESTINATARIO="usuario@dominio.com"
ASUNTO="Generacion de backups  $CODIGO"
MENSAJE="<html>Saludos,<br><br>Relacionamos información sobre los backups generados el dia de hoy $FECHA:<br><br>Se generan los Backups del codigo y de la BD, ambos se comprimen en un solo archivo y se traslada al servidor.<br><b>Recuerde que los backups solo se guardan durante 5 dias.</b> <br><br>\
Enlace del archivo: http://$BACKUP_DIR_REMOTO/$BD/$FECHA/$1/$CODIGO.gz </html>"


# Verificamos si la carpeta de la BD existe
if [ ! -d $CARPETAI ]; then	
	su -l postgres -c "mkdir  $CARPETAI" ] || continue		
fi

# Verificamos si la carpeta de la fecha existe
if [ ! -d $CARPETAF ]; then	
	su -l postgres -c "mkdir  $CARPETAF" ] || continue		
fi


# Verificamos la carpeta am, m o pm existe dentro de la carpeta de fecha
if [ ! -d $CARPETA ]; then
	su -l postgres -c "mkdir $CARPETA" ] || continue
fi


# Generamos los backups de la base de datos
archive=$CARPETA/$BD.backup
archive2=$CARPETA/$BD.dmp

# Verificamos si el backup comprimido existe
# Generamos backup comprimido
if [ ! -e $archive ]; then
	su -l postgres -c "(pg_dump -F c -b -v -f $archive $BD)"	
fi

# Verificamos si el backup normal existe
# Generamos backup normal
if [ ! -e $archive2 ]; then		
	su -l postgres -c "(pg_dump $BD > $archive2)"	
fi


archive3="$CARPETA/$SISTEMA.gz"
# Verificamos si el backup del codigo existe
# Generamos backup del codigo
if [ ! -e $archive3 ]; then		
	cd $PATHCODIGO
	tar -zcvf $SISTEMA.gz *
	mv $SISTEMA.gz $CARPETA/
fi


archive4="$CARPETA/$CODIGO.gz"
# Verificamos si la union de bd y codigo existe
# Generamos union de bd y codigo
if [ ! -e $archive4 ]; then		
	cd $CARPETA	
	tar -zcvf $CODIGO.gz *	
fi



# Verificamos si la union de bd y codigo existe
# Pasamos al servidor de backups
# Eliminamos los arch
if [ -e $archive4 ]; then	
	cd $CARPETA		
	rm $archive $archive2 $archive3
	scp -r $CARPETAI root@$BACKUP_DIR_REMOTO
	rm -rf $CARPETAF	
	echo "$MENSAJE" | mail -a "Content-type: text/html;" -s "$ASUNTO" $DESTINATARIO
fi


