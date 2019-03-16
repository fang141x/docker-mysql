# docker-mysql
使用https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm来安装的mysql5.7。

# 初次运行：

```
docker run -d --name mysql -p 3306:3306 mysql5.7
```
使用docker logs来查看密码：
```
[root@host mysql]# docker logs mysql 
[INFO] No existing MySQL data directory found. Setting up MySQL for the first time.
[INFO] Initializing ...
[INFO] Setting up root user permissions.
[INFO] Shutting down MySQL.
[INFO] MySQL successfully installed.
[INFO] Starting mysqld  Ver 5.7.25 for Linux on x86_64 (MySQL Community Server (GPL))
[INFO] MYSQL Config: /etc/my.cnf
[INFO] MYSQL Password: fVKtzGsS06fQ3o9c
[INFO] MYSQL Data_db_dir: /var/lib/mysql/
[INFO] Auther: https://github.com/fang141x/docker-mysql
[root@host mysql]# docker exec -it mysql mysql -uroot -pfVKtzGsS06fQ3o9c -e "show databases"
mysql: [Warning] Using a password on the command line interface can be insecure.
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```
# 环境变量
- DEBUG_COMPOSE_ENTRYPOINT：是否是DEBUG模式
- MYSQL_ROOT_PASSWORD：root密码
- MYSQL_DEF_DATA：数据库存放位置
- MYSQL_DEF_LOG：数据库日志路径
- MYSQL_DEF_PID：数据库PID路径

# 附1：my.cnf默认配置如下：
```
[client]
socket = /var/sock/mysqld/mysqld.sock
default-character-set=utf8

[mysql]
socket = /var/sock/mysqld/mysqld.sock
default-character-set=utf8

[mysqld]
skip-name-resolve
skip-host-cache
port = 3306
user = mysql
datadir=/var/lib/mysql
max_connections = 200
character-set-server = utf8
bind-address = 0.0.0.0
socket = /var/sock/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid
log-error = /var/log/mysql/error.log
general_log_file = /var/log/mysql/query.log
slow_query_log_file = /var/log/mysql/slow.log
!includedir /etc/my.cnf.d/
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/docker-default.d/
```

# 附2：my.cnf默认配置如下：
以空密码的方式初始化数据库，而且必须使用非root权限启动，可以在my.cnf写上user=mysql，如果不指定，则会启动失败： `mysqld --initialize-insecure --datadir="/var/lib/mysql/" --user=${MYSQL_USER}`

获取my.cnf的两种方法：
```
[root@ee1995b6bc44 /]# my_print_defaults mysqld 
--port=3306
--datadir=/var/lib/mysql
--max_connections=200
--character-set-server=utf8
--bind-address=0.0.0.0
--socket=/var/sock/mysqld/mysqld.sock
--pid-file=/var/run/mysqld/mysqld.pid
--log-error=/var/log/mysql/error.log
--slow_query_log_file=/var/log/mysql/slow.log
--general_log_file=/var/log/mysql/query.log
[root@ee1995b6bc44 /]# 
[root@ee1995b6bc44 /]# 
[root@ee1995b6bc44 /]# 
[root@ee1995b6bc44 /]# my_print_defaults mysqld |grep "^--datadir=" | cut -d= -f2- | tail -n 1
/var/lib/mysql
```
也可以使用mysqld --verbose --help方法来获取
```
[root@xmxyk bin]#./mysqld --verbose --help  2>/dev/null | awk -v key="datadir" '$1 == key { print $2; exit }'
/usr/local/mysql/var/
[root@xmxyk bin]#./mysqld --verbose --help  2>/dev/null | awk -v key="socket" '$1 == key { print $2; exit }'
/tmp/mysql.sock
```