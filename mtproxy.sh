#!/bin/bash
###
 # @Author: Vincent Young
 # @Date: 2022-07-01 15:29:23
 # @LastEditors: lbg43
 # @LastEditTime: 2022-07-30 19:26:45
 # @FilePath: /MTProxy-/mtproxy.sh
 # @Telegram: https://t.me/missuo
 # 
 # Copyright © 2022 by Vincent, All Rights Reserved. 
### 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Define Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Make sure run with root
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}]Please run this script with ROOT!" && exit 1

# Base directory for MTProxy instances
INSTANCES_DIR="/etc/mtproxy"
# Default instance name
DEFAULT_INSTANCE="default"

download_file(){
	echo "Checking System..."

	bit=`uname -m`
	if [[ ${bit} = "x86_64" ]]; then
		bit="amd64"
    elif [[ ${bit} = "aarch64" ]]; then
        bit="arm64"
    else
	    bit="386"
    fi

    last_version=$(curl -Ls "https://api.github.com/repos/9seconds/mtg/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ ! -n "$last_version" ]]; then
        echo -e "${red}Failure to detect mtg version may be due to exceeding Github API limitations, please try again later."
        exit 1
    fi
    echo -e "Latest version of mtg detected: ${last_version}, start installing..."
    version=$(echo ${last_version} | sed 's/v//g')
    wget -N --no-check-certificate -O mtg-${version}-linux-${bit}.tar.gz https://github.com/9seconds/mtg/releases/download/${last_version}/mtg-${version}-linux-${bit}.tar.gz
    if [[ ! -f "mtg-${version}-linux-${bit}.tar.gz" ]]; then
        echo -e "${red}Download mtg-${version}-linux-${bit}.tar.gz failed, please try again."
        exit 1
    fi
    tar -xzf mtg-${version}-linux-${bit}.tar.gz
    mv mtg-${version}-linux-${bit}/mtg /usr/bin/mtg
    rm -f mtg-${version}-linux-${bit}.tar.gz
    rm -rf mtg-${version}-linux-${bit}
    chmod +x /usr/bin/mtg
    echo -e "mtg-${version}-linux-${bit}.tar.gz installed successfully, start to configure..."
}

# Create instance directory structure
setup_instance_dir() {
    # Create base directory if it doesn't exist
    mkdir -p ${INSTANCES_DIR}
}

configure_mtg(){
    setup_instance_dir
    
    echo ""
    read -p "Enter instance name (default: default): " instance_name
    [ -z "${instance_name}" ] && instance_name="${DEFAULT_INSTANCE}"
    
    # Create instance directory
    instance_dir="${INSTANCES_DIR}/${instance_name}"
    mkdir -p ${instance_dir}
    
    # Check if instance already exists
    if [ -f "${instance_dir}/mtg.toml" ]; then
        echo -e "${yellow}Instance '${instance_name}' already exists. Do you want to reconfigure it? (y/n)${plain}"
        read -p "" reconfigure
        if [[ "${reconfigure}" != "y" && "${reconfigure}" != "Y" ]]; then
            echo "Configuration aborted."
            return
        fi
    fi
    
    echo -e "Configuring mtg instance: ${instance_name}..."
    
    # Create config file for this instance
    cp /etc/mtg.toml ${instance_dir}/mtg.toml 2>/dev/null || wget -N --no-check-certificate -O ${instance_dir}/mtg.toml https://raw.githubusercontent.com/lbg43/MTProxy-/main/mtg.toml
    
    echo ""
    read -p "Please enter a spoofed domain (default itunes.apple.com): " domain
	[ -z "${domain}" ] && domain="itunes.apple.com"

	echo ""
    read -p "Enter the port to be listened to (default 8443):" port
	[ -z "${port}" ] && port="8443"

    # Generate secret with server information
    secret=$(mtg generate-secret --hex $domain)
    
    echo "Waiting configuration..."

    # Create the config file with the proper format
    cat > ${instance_dir}/mtg.toml <<EOF
secret = "${secret}"
bind-to = "0.0.0.0:${port}"
name = "MTPROTO"
doh-ip = "8.8.8.8"
EOF

    echo "mtg instance '${instance_name}' configured successfully, start to configure systemctl..."
    
    # Save instance info for later use
    echo "${port}" > ${instance_dir}/port
    echo "${secret}" > ${instance_dir}/secret
    echo "${domain}" > ${instance_dir}/domain
    
    configure_systemctl "${instance_name}"
}

configure_systemctl(){
    instance_name=$1
    instance_dir="${INSTANCES_DIR}/${instance_name}"
    service_name="mtg-${instance_name}"
    
    echo -e "Configuring systemctl for instance: ${instance_name}..."
    
    # Create systemd service file
    cat > /etc/systemd/system/${service_name}.service <<EOF
[Unit]
Description=mtg - MTProto proxy server (${instance_name})
Documentation=https://github.com/lbg43/MTProxy-
After=network.target

[Service]
ExecStart=/usr/bin/mtg run ${instance_dir}/mtg.toml
Restart=always
RestartSec=3
DynamicUser=true
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target 
EOF

    systemctl daemon-reload
    systemctl enable ${service_name}
    systemctl start ${service_name}
    
    echo "mtg instance '${instance_name}' configured successfully, start to configure firewall..."
    
    # Firewall configuration (only once)
    if [ "${instance_name}" = "${DEFAULT_INSTANCE}" ]; then
        systemctl disable firewalld 2>/dev/null
        systemctl stop firewalld 2>/dev/null
        ufw disable 2>/dev/null
    fi
    
    echo "mtg instance '${instance_name}' started successfully, enjoy it!"
    echo ""
    
    port=$(cat ${instance_dir}/port)
    secret=$(cat ${instance_dir}/secret)
    public_ip=$(curl -s ipv4.ip.sb)
    
    # Build complete links
    subscription_config="tg://proxy?server=${public_ip}&port=${port}&secret=${secret}"
    subscription_link="https://t.me/proxy?server=${public_ip}&port=${port}&secret=${secret}"
    
    echo -e "Instance: ${instance_name}"
    echo -e "Port: ${port}"
    echo -e "${subscription_config}"
    echo -e "${subscription_link}"
}

list_instances() {
    echo -e "${green}MTProxy Instances:${plain}"
    echo "-------------------------"
    
    if [ ! -d "${INSTANCES_DIR}" ] || [ -z "$(ls -A ${INSTANCES_DIR} 2>/dev/null)" ]; then
        echo -e "${yellow}No instances found.${plain}"
        return
    fi
    
    for instance in $(ls ${INSTANCES_DIR}); do
        instance_dir="${INSTANCES_DIR}/${instance}"
        if [ -f "${instance_dir}/mtg.toml" ]; then
            port=$(cat ${instance_dir}/port 2>/dev/null || echo "unknown")
            status=$(systemctl is-active mtg-${instance} 2>/dev/null || echo "unknown")
            
            if [ "${status}" = "active" ]; then
                status_color="${green}${status}${plain}"
            else
                status_color="${red}${status}${plain}"
            fi
            
            echo -e "Instance: ${instance}, Port: ${port}, Status: ${status_color}"
        fi
    done
    echo "-------------------------"
}

select_instance() {
    if [ ! -d "${INSTANCES_DIR}" ] || [ -z "$(ls -A ${INSTANCES_DIR} 2>/dev/null)" ]; then
        echo -e "${yellow}No instances found.${plain}"
        return ""
    fi
    
    list_instances
    
    echo ""
    read -p "Enter instance name: " selected_instance
    
    if [ ! -d "${INSTANCES_DIR}/${selected_instance}" ]; then
        echo -e "${red}Instance '${selected_instance}' not found.${plain}"
        return ""
    fi
    
    echo "${selected_instance}"
}

change_port(){
    instance=$(select_instance)
    [ -z "${instance}" ] && return
    
    instance_dir="${INSTANCES_DIR}/${instance}"
    service_name="mtg-${instance}"
    
    read -p "Enter the port you want to modify for instance '${instance}' (default 8443):" port
	[ -z "${port}" ] && port="8443"
    
    sed -i "s/bind-to.*/bind-to = \"0.0.0.0:${port}\"/g" ${instance_dir}/mtg.toml
    echo "${port}" > ${instance_dir}/port
    
    echo "Restarting MTProxy instance '${instance}'..."
    systemctl restart ${service_name}
    echo "MTProxy instance '${instance}' restarted successfully!"
    
    # Display updated connection info
    public_ip=$(curl -s ipv4.ip.sb)
    secret=$(cat ${instance_dir}/secret)
    
    subscription_config="tg://proxy?server=${public_ip}&port=${port}&secret=${secret}"
    subscription_link="https://t.me/proxy?server=${public_ip}&port=${port}&secret=${secret}"
    
    echo -e "Updated connection info:"
    echo -e "${subscription_config}"
    echo -e "${subscription_link}"
}

change_secret(){
    instance=$(select_instance)
    [ -z "${instance}" ] && return
    
    instance_dir="${INSTANCES_DIR}/${instance}"
    service_name="mtg-${instance}"
    
    echo -e "Please note that unauthorized modification of Secret may cause MTProxy to not function properly."
    read -p "Enter the secret you want to modify for instance '${instance}':" secret
    
    domain=$(cat ${instance_dir}/domain 2>/dev/null || echo "itunes.apple.com")
	[ -z "${secret}" ] && secret="$(mtg generate-secret --hex ${domain})"
    
    sed -i "s/secret.*/secret = \"${secret}\"/g" ${instance_dir}/mtg.toml
    echo "${secret}" > ${instance_dir}/secret
    
    echo "Secret changed successfully!"
    echo "Restarting MTProxy instance '${instance}'..."
    systemctl restart ${service_name}
    echo "MTProxy instance '${instance}' restarted successfully!"
    
    # Display updated connection info
    public_ip=$(curl -s ipv4.ip.sb)
    port=$(cat ${instance_dir}/port)
    
    subscription_config="tg://proxy?server=${public_ip}&port=${port}&secret=${secret}"
    subscription_link="https://t.me/proxy?server=${public_ip}&port=${port}&secret=${secret}"
    
    echo -e "Updated connection info:"
    echo -e "${subscription_config}"
    echo -e "${subscription_link}"
}

update_mtg(){
    echo -e "Updating mtg..."
    download_file
    
    # Restart all instances
    if [ -d "${INSTANCES_DIR}" ]; then
        for instance in $(ls ${INSTANCES_DIR}); do
            if [ -f "${INSTANCES_DIR}/${instance}/mtg.toml" ]; then
                echo "Restarting MTProxy instance '${instance}'..."
                systemctl restart mtg-${instance}
                echo "MTProxy instance '${instance}' restarted successfully!"
            fi
        done
    else
        echo "No instances found to restart."
    fi
    
    echo "mtg updated successfully!"
}

start_instance() {
    instance=$(select_instance)
    [ -z "${instance}" ] && return
    
    service_name="mtg-${instance}"
    
    echo "Starting MTProxy instance '${instance}'..."
    systemctl start ${service_name}
    systemctl enable ${service_name}
    echo "MTProxy instance '${instance}' started successfully!"
}

stop_instance() {
    instance=$(select_instance)
    [ -z "${instance}" ] && return
    
    service_name="mtg-${instance}"
    
    echo "Stopping MTProxy instance '${instance}'..."
    systemctl stop ${service_name}
    systemctl disable ${service_name}
    echo "MTProxy instance '${instance}' stopped successfully!"
}

restart_instance() {
    instance=$(select_instance)
    [ -z "${instance}" ] && return
    
    service_name="mtg-${instance}"
    
    echo "Restarting MTProxy instance '${instance}'..."
    systemctl restart ${service_name}
    echo "MTProxy instance '${instance}' restarted successfully!"
}

remove_instance() {
    instance=$(select_instance)
    [ -z "${instance}" ] && return
    
    service_name="mtg-${instance}"
    instance_dir="${INSTANCES_DIR}/${instance}"
    
    echo -e "${yellow}Are you sure you want to remove instance '${instance}'? (y/n)${plain}"
    read -p "" confirm
    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        echo "Removal aborted."
        return
    fi
    
    echo "Removing MTProxy instance '${instance}'..."
    systemctl stop ${service_name}
    systemctl disable ${service_name}
    rm -f /etc/systemd/system/${service_name}.service
    systemctl daemon-reload
    
    rm -rf ${instance_dir}
    echo "MTProxy instance '${instance}' removed successfully!"
}

uninstall_all() {
    echo -e "${yellow}Are you sure you want to uninstall MTProxy and remove all instances? (y/n)${plain}"
    read -p "" confirm
    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        echo "Uninstall aborted."
        return
    fi
    
    echo "Uninstalling MTProxy..."
    
    # Stop and remove all instances
    if [ -d "${INSTANCES_DIR}" ]; then
        for instance in $(ls ${INSTANCES_DIR}); do
            if [ -f "${INSTANCES_DIR}/${instance}/mtg.toml" ]; then
                service_name="mtg-${instance}"
                systemctl stop ${service_name} 2>/dev/null
                systemctl disable ${service_name} 2>/dev/null
                rm -f /etc/systemd/system/${service_name}.service
            fi
        done
    fi
    
    systemctl daemon-reload
    
    # Remove all files
    rm -rf ${INSTANCES_DIR}
    rm -rf /usr/bin/mtg
    rm -rf /etc/mtg.toml
    rm -rf /etc/systemd/system/mtg.service
    
    echo "Uninstall MTProxy successfully!"
}

start_menu() {
    clear
    echo -e "  MTProxy v2 Multi-Instance Installation
---- by lbg43 | github.com/lbg43/MTProxy- ----
 ${green} 1.${plain} Install MTProxy (New Instance)
 ${green} 2.${plain} Uninstall MTProxy (All Instances)
————————————
 ${green} 3.${plain} List All Instances
 ${green} 4.${plain} Start Instance
 ${green} 5.${plain} Stop Instance
 ${green} 6.${plain} Restart Instance
 ${green} 7.${plain} Remove Instance
————————————
 ${green} 8.${plain} Change Listen Port
 ${green} 9.${plain} Change Secret
 ${green}10.${plain} Update MTProxy
————————————
 ${green} 0.${plain} Exit
————————————" && echo

	read -e -p " Please enter the number [0-10]: " num
	case "$num" in
    1)
		download_file
        configure_mtg
		;;
    2)
        uninstall_all
        ;;
    3) 
        list_instances
        ;;
    4) 
        start_instance
        ;;
    5)  
        stop_instance
        ;;
    6) 
        restart_instance
        ;;
    7)
        remove_instance
        ;;
    8)
        change_port
        ;;
    9)
        change_secret
        ;;
    10)
        update_mtg
        ;;
    0) exit 0
        ;;
    *) echo -e "${red}Error: Please enter a number [0-10]${plain}"
        ;;
    esac
    
    # Return to menu after operation
    echo ""
    read -p "Press Enter to continue..." dummy
    start_menu
}
start_menu 
