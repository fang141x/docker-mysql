#!/bin/bash

run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi

	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"	#绿
	_clr_info="\033[0;34m"	#蓝
	_clr_warn="\033[0;33m"	#黄
	_clr_err="\033[0;31m"	#红
	_clr_rst="\033[0m"		#结束标记

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}

get_mysql_default_config() {
	_key="${1}"
	mysqld --verbose --help  2>/dev/null  | awk -v key="${_key}" '$1 == key { print $2; exit }'
}

if [ "$MYSQL_ROOT_PASSWORD" = "**Random**" ]; then
    export MYSQL_ROOT_PASSWORD=`cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c${1:-16}`
fi

if [ "$MYSQL_SOCKET_DIR"X = ""X ]; then
    export MYSQL_SOCKET_DIR=`get_mysql_default_config socket`
fi

if [ "$DB_DATA_DIR"X = ""X ]; then
    export DB_DATA_DIR="$( get_mysql_default_config "datadir" )"
fi

if [ -d "${DB_DATA_DIR}/mysql" ] && [ "$( ls -A "${DB_DATA_DIR}/mysql" )" ]; then
	log "info" "Found existing data directory. MySQL already setup."
else
	log "info" "No existing MySQL data directory found. Setting up MySQL for the first time."
	# Create datadir if not exist yet
	if [ ! -d "${DB_DATA_DIR}" ]; then
		log "info" "Creating empty data directory in: ${DB_DATA_DIR}."
		run "mkdir -p ${DB_DATA_DIR}"
		run "chown -R ${MY_USER}:${MY_GROUP} ${DB_DATA_DIR}"
		run "chmod 0777 ${MY_USER}:${MY_GROUP} ${DB_DATA_DIR}"
	fi
	#initialize no password
	run "mysqld --initialize-insecure --datadir=${DB_DATA_DIR} --user=${MYSQL_USER}"
	run "mysqld --skip-networking &"
	for i in `seq 1 60`;do
		if echo 'SELECT 1' |  mysql --protocol=socket -uroot  > /dev/null 2>&1; then
			break
		fi
		log "info" "Initializing ..."
		sleep 1s
		i=$(( i + 1 ))
	done
	pid="$(pgrep mysqld | head -1)"
	if [ "${pid}" = "" ]; then
		log "err" "Could not find running MySQL PID."
		log "err" "MySQL init process failed."
		exit 1
	fi
	
	# Bootstrap MySQL
	log "info" "Setting up root user permissions."
	echo "DELETE FROM mysql.user ;" | mysql --protocol=socket -uroot
	echo "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;" | mysql --protocol=socket -uroot
	echo "GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;" | mysql --protocol=socket -uroot
	echo "DROP DATABASE IF EXISTS test ;" | mysql --protocol=socket -uroot
	echo "FLUSH PRIVILEGES ;" | mysql --protocol=socket -uroot
	
	log "info" "Shutting down MySQL."
	run "kill -s TERM ${pid}"
	sleep 5
	if pgrep mysqld >/dev/null 2>&1; then
		log "err" "Unable to shutdown MySQL server."
		log "err" "MySQL init process failed."
		exit 1
	fi
	log "info" "MySQL successfully installed."
fi

log "info" "Starting $(mysqld --version)"
log "info" "MYSQL Config: /etc/my.cnf"
log "info" "MYSQL Password: $MYSQL_ROOT_PASSWORD"
log "info" "MYSQL Data_db_dir: $DB_DATA_DIR"
log "info" "Auther: https://github.com/fang141x/docker-mysql"
exec mysqld
