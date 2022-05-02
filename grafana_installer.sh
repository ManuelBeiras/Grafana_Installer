#!/bin/bash
#########################################################################################################
##Grafana installation script 											                               ##
##Date: 14/10/2021                                                                                     ##
##Version 1.0:  Allows simple installation of Grafana.							                   	   ##
##        If the installation of all components is done on the same machine                            ##
##        a fully operational version remains. If installed on different machines                      ##
##        it is necessary to modify the configuration manually.                                        ##
##        Fully automatic installation only requires a password change at the end if you want.         ##
##                                                                                                     ##
##Authors:                                                                                             ##
##			Manuel José Beiras Belloso																   ##
##			Rubén Míguez Bouzas										                                   ##
##			Luis Mera Castro										                                   ##
#########################################################################################################

# Initial check if the user is root and the OS is Ubuntu
function initialCheck() {
	if ! isRoot; then
		echo "The script must be executed as a root"
		exit 1
	fi
}

# Check if the user is root
function isRoot() {
    if [ "$EUID" -ne 0 ]; then
		return 1
	fi
	checkOS
}

# Check the operating system
function checkOS() {
    source /etc/os-release
	if [[ $ID == "ubuntu" ]]; then
	    OS="ubuntu"
	    MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
	    if [[ $MAJOR_UBUNTU_VERSION -lt 20 ]]; then
            echo "⚠️ This script it's not tested in your Ubuntu version. You want to continue?"
			echo ""
			CONTINUE='false'
			until [[ $CONTINUE =~ (y|n) ]]; do
			    read -rp "Continue? [y/n]: " -e CONTINUE
			done
			if [[ $CONTINUE == "n" ]]; then
				exit 1
			fi
		fi
		questionsMenu
	else
        echo "Your OS it's not Ubuntu, in the case you are using Centos you can continue from here. Press [Y]"
		CONTINUE='false'
		until [[ $CONTINUE =~ (y|n) ]]; do
			read -rp "Continue? [y/n]: " -e CONTINUE
		done
		if [[ $CONTINUE == "n" ]]; then
			exit 1
		fi
		OS="centos"
		questionsMenu
	fi
}

function questionsMenu() {
	echo -e "What you want to do ?"
	echo "1. Install Grafana."
	echo "2. Uninstall Grafana."
	echo "0. exit."
	read -e CONTINUE
	if [[ $CONTINUE == 1 ]]; then
		installGrafana
	elif [[ $CONTINUE == 2 ]]; then
		uninstallGrafana
	elif [[ $CONTINUE == 0 ]]; then
		exit 1
	else
		echo "invalid option !"
		clear
		questionsMenu
	fi
}

function installGrafana() {
    if [[ $OS == "ubuntu" ]]; then
        if dpkg -l | grep grafana > /dev/null; then
            echo "Grafana it's already installed on the system."
            echo "Installation cancelled."
        else
            # The prerequisites are installed and the repository key is added.
			apt install -y apt-transport-https
			apt install -y software-properties-common wget
			wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
			# Add repository to the sources list.
			echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list
			apt -y update
			# Install Grafana.
			apt install -y grafana
			systemctl daemon-reload
			service grafana-server start
			sudo systemctl enable grafana-server.service
			questionsPluginZabbix
        fi
    fi
}

function questionsPluginZabbix() {
    echo "Do you want to install the zabbix plugin if you have a zabbix installed ?"
    echo "1. Yes."
    echo "2. Back to main menu."
    read -e CONTINUE
    if [[ $CONTINUE == 1 ]]; then
        installPluginZabbix
    elif [[ $CONTINUE == 2 ]]; then
		echo "Grafana installation succeded"
        questionsMenu
    else
        echo "invalid option !"
    fi
}

function installPluginZabbix() {
	grafana-cli plugins list-remote
	grafana-cli plugins install alexanderzobnin-zabbix-app
	sed -i 's|allow_loading_unsigned_plugins =|allow_loading_unsigned_plugins = alexanderzobnin-zabbix-datasource|' /usr/share/grafana/conf/defaults.ini 
	service grafana-server restart
	echo ""
    echo ""
    echo ""
    echo "Zabbix plugin for Grafana installed correctly."
    echo ""
    echo ""
    echo ""
}

function uninstallGrafana() {
    apt -y remove grafana
    apt -y purge grafana
    apt -y autoremove
    apt -y autoclean
	rm -r /etc/grafana/
	rm -r /var/lib/grafana/
    echo ""
    echo ""
    echo ""
    echo "Grafana uninstalled."
    echo ""
    echo ""
    echo ""
}

initialCheck