FROM centos:7
MAINTAINER fangdm <fang2000@vip.qq.com>

LABEL image="mysql-5.7" vendor=fangdm build-date="2019-03-15"
ENV REPO_URL="https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm" \
    MYSQL_ROOT_PASSWORD="**Random**" \
    MYSQL_VERSION=5.7 \
    MYSQL_USER=mysql \
    MYSQL_GROUP=mysql \
    MYSQL_UID=27 \
    MYSQL_GID=27 

COPY docker-entrypoint.sh /
RUN groupadd -g ${MYSQL_GID} -r ${MYSQL_GROUP} && chmod 755 /docker-entrypoint.sh && \
    adduser ${MYSQL_USER} -u ${MYSQL_UID} -s /sbin/nologin -M -g ${MYSQL_GROUP}

RUN yum install -y epel-release && \
    rpm -ivh ${REPO_URL} && \
    yum-config-manager --disable mysql55-community && \
    yum-config-manager --disable mysql56-community && \
    yum-config-manager --disable mysql80-community && \
    yum-config-manager --enable mysql57-community && \
    yum install -y mysql-community-server  && \
    yum -y autoremove && \
    yum clean all
	
ENV MYSQL_BASE_INCL="/etc/my.cnf.d" \
	MYSQL_CUST_INCL1="/etc/mysql/conf.d" \
	MYSQL_MY_CNF="/etc/my.cnf" \
	MYSQL_CUST_INCL2="/etc/mysql/docker-default.d" \
	MYSQL_DEF_DATA="/var/lib/mysql" \
	MYSQL_DEF_PID="/var/run/mysqld" \
	MYSQL_DEF_SOCK="/var/sock/mysqld" \
	MYSQL_DEF_LOG="/var/log/mysql"

ENV	MYSQL_LOG_SLOW="${MYSQL_DEF_LOG}/slow.log" \
	MYSQL_LOG_ERROR="${MYSQL_DEF_LOG}/error.log" \
	MYSQL_LOG_QUERY="${MYSQL_DEF_LOG}/query.log"
	
RUN rm -rf $MYSQL_BASE_INCL $MYSQL_CUST_INCL1 $MYSQL_CUST_INCL2 $MYSQL_DEF_DATA $MYSQL_DEF_SOCK $MYSQL_DEF_LOG && \
	mkdir -p $MYSQL_BASE_INCL $MYSQL_CUST_INCL1 $MYSQL_CUST_INCL2 $MYSQL_DEF_DATA $MYSQL_DEF_SOCK $MYSQL_DEF_LOG && \
	chmod 0755 $MYSQL_BASE_INCL $MYSQL_CUST_INCL1 $MYSQL_CUST_INCL2 $MYSQL_DEF_DATA $MYSQL_DEF_SOCK $MYSQL_DEF_LOG && \
	chown ${MYSQL_USER}:${MYSQL_GROUP} $MYSQL_BASE_INCL $MYSQL_CUST_INCL1 $MYSQL_CUST_INCL2 $MYSQL_DEF_DATA $MYSQL_DEF_SOCK $MYSQL_DEF_LOG
	
RUN echo "[client]"					>$MYSQL_MY_CNF && \
	echo "socket = ${MYSQL_DEF_SOCK}/mysqld.sock" 	>>$MYSQL_MY_CNF && \
	echo -e "default-character-set=utf8\n" 		>>$MYSQL_MY_CNF && \
	echo "[mysql]" 					>>$MYSQL_MY_CNF && \
	echo "socket = ${MYSQL_DEF_SOCK}/mysqld.sock" 	>>$MYSQL_MY_CNF && \
	echo -e "default-character-set=utf8\n" 		>>$MYSQL_MY_CNF && \
	echo "[mysqld]"					>>$MYSQL_MY_CNF && \
	echo "skip-name-resolve"			>>$MYSQL_MY_CNF && \
	echo "skip-host-cache"				>>$MYSQL_MY_CNF && \
	echo "port = 3306" 				>>$MYSQL_MY_CNF && \
	echo "user = ${MYSQL_USER}"			>>$MYSQL_MY_CNF && \
	echo "datadir=$MYSQL_DEF_DATA" 			>>$MYSQL_MY_CNF && \
	echo "max_connections = 200" 			>>$MYSQL_MY_CNF && \
	echo "character-set-server = utf8" 		>>$MYSQL_MY_CNF && \
	echo "bind-address = 0.0.0.0" 			>>$MYSQL_MY_CNF && \
	echo "socket = ${MYSQL_DEF_SOCK}/mysqld.sock" 	>>$MYSQL_MY_CNF && \
	echo "pid-file = ${MYSQL_DEF_PID}/mysqld.pid" 	>>$MYSQL_MY_CNF && \
	echo "log-error = ${MYSQL_LOG_ERROR}" 		>>$MYSQL_MY_CNF && \
	echo "general_log_file = ${MYSQL_LOG_QUERY}" 	>>$MYSQL_MY_CNF && \
	echo "slow_query_log_file = ${MYSQL_LOG_SLOW}" 	>>$MYSQL_MY_CNF && \
	echo "!includedir ${MYSQL_BASE_INCL}/" 		>>$MYSQL_MY_CNF && \
	echo "!includedir ${MYSQL_CUST_INCL1}/" 	>>$MYSQL_MY_CNF && \
	echo "!includedir ${MYSQL_CUST_INCL2}/" 	>>$MYSQL_MY_CNF
	
EXPOSE 3306
VOLUME ["$MYSQL_DEF_DATA","$MYSQL_DEF_LOG","$MYSQL_CUST_INCL1","$MYSQL_CUST_INCL2"]
ENTRYPOINT ["/docker-entrypoint.sh"]

