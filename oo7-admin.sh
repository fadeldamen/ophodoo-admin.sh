#!/bin/bash
################################################################################
# A one-line installation for OpenERP 7.0 server instances
#-------------------------------------------------------------------------------
# USAGE:
#
# * Setup openerp server and create a first OpenERP7 7 instance
#   oo7-admin install [name1] --full
#
# * Create an additional OpenERP7 7 instance
#   oo7-admin install [name2]
#
# * Start one OpenERP instance (to the terminal)
# 	oo7-admin start [name2] [server options]
#
# EXAMPLE:
# oo7-admin install development --full
# oo7-admin install staging
# oo7-admin start staging --xmlrpc-port=8080 &
# oo7-admin start development --xmlrpc-port=8080 --debug
# Original Author:	Daniel Reis, 2013
# Modified by:		FRANCOIS Laurent 2015
################################################################################
#  Copyright 2013 Nicholas <nicholas.riegel@gmail.com>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public Licesudo apt-get install postgresqlnse
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.

#fixed parameters:
OO_USER="openerp"
OO_HOME="/opt/openerp"

case "$1" in
install)
	#--------------------------------------------------
	# Install required dependencies
	#--------------------------------------------------
	if [ "$3" = "--full" ] ; then
		#Make this script available anywhere:
		#sudo ln -sf /usr/local/bin $0
		echo -e "\n---- Install PostgreSQL ----"
		sudo apt-get install postgresql
		
		echo -e "\n---- Install tool debian packages ----"
		yes | sudo apt-get install git bzr bzrtools python-pip

		echo -e "\n---- Install python debian packages ----"
		yes | sudo apt-get install python-dateutil python-docutils python-feedparser \
		python-gdata python-jinja2 python-ldap python-libxslt1 python-lxml python-mako \
		python-mock python-openid python-psycopg2 python-psutil python-pybabel \
		python-pychart python-pydot python-pyparsing python-reportlab python-simplejson \
		python-tz python-unittest2 python-vatnumber python-vobject python-webdav \
		python-werkzeug python-xlwt python-yaml python-zsi
		
		echo -e "\n---- Install python libraries ----"
		sudo pip install gdata
		
		echo -e "\n---- Create system user ----"
		sudo adduser --system --quiet --shell=/bin/bash --home=$OO_HOME --gecos 'OpenERP' --group $OO_USER
		sudo mkdir /var/log/$OO_USER
		sudo chown $OO_USER:$OO_USER /var/log/$OO_USER
		sudo mkdir -p $OO_HOME/$OO_USER
		sudo chown $OO_USER:$OO_USER $OO_HOME/$OO_USER
	fi
	
	#--------------------------------------------------
	# Create a new instance
	#--------------------------------------------------
	INSTANCE=$2
	echo -e "\n==== Create instance $INSTANCE ===="

	echo "* Create instance directory"
	mkdir -p $OO_HOME/$INSTANCE

	echo "* Create postgres user"
	echo "A new PostgreSQL user, openerp-"$INSTANCE" will be created."
	echo "Enter the network port for this instance (i.e. 8070, 8071, etc):" 
	read instance_port
	sudo su -c "createuser -e --createdb --no-createrole --no-superuser openerp-$INSTANCE" postgres	
	if [ -d $OO_HOME/$INSTANCE/server ] ; then
		echo "* Server directory exists: skipping"
	else
		echo -e "* Download files"
		#Download nightly builds
		mkdir -p $OO_HOME/downloads
		wget --no-clobber http://nightly.openerp.com/7.0/nightly/src/openerp-7.0-latest.tar.gz -P $OO_HOME/downloads
		echo -e "* Uncompress files"
		rm -rf $OO_HOME/downloads/tmp
		mkdir -p $OO_HOME/downloads/tmp
		tar xvf $OO_HOME/downloads/openerp-7.0-latest.tar.gz --directory=$OO_HOME/downloads/tmp
		echo -e "* Install files"
		mkdir -p $OO_HOME/$INSTANCE/server
		mv $OO_HOME/downloads/tmp/`ls $OO_HOME/downloads/tmp/`/* $OO_HOME/$INSTANCE/server
		#bzr co lp:openerp-web/7.0 $OO_HOME/$INSTANCE/web
		#bzr co lp:openobject-server/7.0 $OO_HOME/$INSTANCE/server
		#bzr co lp:openobject-addons/7.0 $OO_HOME/$INSTANCE/addons
	fi
	
	echo -e "* Create server config file"
	cp $OO_HOME/$INSTANCE/server/install/openerp-server.conf $OO_HOME/$INSTANCE --backup=numbered
	sed -i s/"db_user = .*"/"db_user = openerp-$INSTANCE"/g $OO_HOME/$INSTANCE/openerp-server.conf
	#sed -i s/"db_password = .*"/"db_password = $instance_pass"/g $OO_HOME/$INSTANCE/openerp-server.conf
	echo "xmlrpc_port = $instance_port" >> $OO_HOME/$INSTANCE/openerp-server.conf
	echo "logfile = /var/log/openerp/openerp-$INSTANCE.log" >> $OO_HOME/$INSTANCE/openerp-server.conf
	
	#
	#echo "addons_path=/opt/openerp/$INSTANCE/addons,/opt/openerp/$INSTANCE/web/addons" >> $OO_HOME/$INSTANCE/openerp-server.conf
	echo "#!/bin/sh
sudo -u $OO_USER $OO_HOME/$INSTANCE/server/openerp-server --config=$OO_HOME/$INSTANCE/openerp-server.conf \$*
" > $OO_HOME/$INSTANCE/start.sh
	chmod 755 $OO_HOME/$INSTANCE/start.sh
	;;

start)
	INSTANCE=$2
	shift 2
	$OO_HOME/$INSTANCE/start.sh $*
	;;
	
esac
echo "Done!"

# TODO IDEAS:  add options to
# * set listening xmlrpc port
# * start in background, see instances running, and stop instances
# * set instance to autostart on boot
# * provide better conf file template
# * install from source
# * install and add an additional addons directory to an existing instance
# * update instance files
# * remove instance
# * rebuild and run tests on throw-away instances