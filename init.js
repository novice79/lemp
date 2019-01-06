#!/usr/bin/node
const fs = require('fs');
const { spawn, spawnSync, exec, execSync } = require('child_process');
// some util functions begin-----------------------
function pad(num, size) {
    let s = num + "";
    while (s.length < size) s = "0" + s;
    return s;
}
const now_str =
    (dt = new Date()) =>
        `${dt.getFullYear()}-${dt.getMonth() + 1}-${dt.getDate()} ${dt.getHours()}:${dt.getMinutes()}:${dt.getSeconds()}.${pad(dt.getMilliseconds(), 3)}`
            .replace(/\b\d\b/g, '0$&');

console.logCopy = console.log.bind(console);
console.log = function (...args) {
    if (args.length) {
        this.logCopy(`[${now_str()}]`, ...args);
    }
};
// some thing like: rm -rf temp/
function deleteFolderRecursive(path) {
    if (fs.existsSync(path)) {
        fs.readdirSync(path).forEach((file, index) => {
            const curPath = path + "/" + file;
            if (fs.lstatSync(curPath).isDirectory()) { // recurse
                deleteFolderRecursive(curPath);
            } else { // delete file
                fs.unlinkSync(curPath);
            }
        });
        fs.rmdirSync(path);
    }
};
// some thing like: rm -rf temp/*
function clearDir(path) {
    fs.readdirSync(path).forEach((file, index) => {
        const curPath = path + "/" + file;
        if (fs.lstatSync(curPath).isDirectory()) { // recurse
            deleteFolderRecursive(curPath);
        } else { // delete file
            fs.unlinkSync(curPath);
        }
    });
}
// util functions end -----------------------------
execSync('chown -R mysql:mysql /var/lib/mysql');
if (!fs.existsSync("/var/lib/mysql/mysql")) {
    // clear files in /var/lib/mysql
    clearDir('/var/lib/mysql');
    execSync('mysqld --initialize --user=mysql --datadir=/var/lib/mysql');  // or --initialize-insecure
}
const uid = parseInt(execSync('id -u mysql').toString());
const gid = parseInt(execSync('id -g mysql').toString());
const randInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
let s_id = 1, extra_para = '', init_sql;
const sql_init_file = '/tmp/mysql-init.sql';
// get environment variables:
const MYSQL_ROOT_PASSWORD = process.env.MYSQL_ROOT_PASSWORD || 'freego';
const MYSQL_DATABASE = process.env.MYSQL_DATABASE;
const MYSQL_USER = process.env.MYSQL_USER;
const MYSQL_PASSWORD = process.env.MYSQL_PASSWORD || 'freego';
// first two are node and script name
const paras = process.argv.slice(2)
if (paras.length == 0) {
    init_sql =
    `
    CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
    GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
    CREATE USER IF NOT EXISTS 'david'@'%' IDENTIFIED BY 'freego';
    GRANT ALL ON *.* TO 'david'@'%';
    CREATE USER IF NOT EXISTS 'slaveuser'@'%' IDENTIFIED WITH sha256_password BY 'freego';
    GRANT REPLICATION SLAVE ON *.* TO 'slaveuser'@'%';
    ${MYSQL_DATABASE ? `CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} ;` : ''}
    ${MYSQL_USER ? `CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';` : ''}
    ${MYSQL_DATABASE && MYSQL_USER ? `GRANT ALL ON *.* TO '${MYSQL_USER}'@'%';` : ''}
    FLUSH PRIVILEGES;
    `;
} else {
    init_sql =
    `
    CHANGE MASTER TO
    MASTER_HOST='${paras[0]}',
    MASTER_PORT=3306,
    MASTER_USER='slaveuser',
    MASTER_PASSWORD='freego',
    MASTER_AUTO_POSITION=1;
    START SLAVE;
    `;
    s_id = randInt(2, 2 ** 32);
    extra_para = '--master-info-repository=TABLE';
}
fs.writeFileSync(sql_init_file, init_sql);

(function start_mysql() {
    const start_dt = new Date().getTime();
    const mysqld = exec(
        `mysqld --init-file="${sql_init_file}" --server-id=${s_id} --log-bin=mysql-bin --gtid-mode=ON --enforce-gtid-consistency=true --log-slave-updates ${extra_para}`,
        { uid, gid }
    );
    mysqld.stdout.on('data', data => console.log(data));
    mysqld.stderr.on('data', data => console.log(data));
    mysqld.on('close', (code) => {
        console.log(`mysqld exited with code ${code}`);
        const end_dt = new Date().getTime();
        if (end_dt - start_dt > 3600 * 1000) {
            // restart mysqld
            setTimeout(() => start_mysql(), 2000);
        }
    });
})();
(function start_php() {
    const start_dt = new Date().getTime();
    const php = exec( `php-fpm -F -O` );
    php.stdout.on('data', data => console.log(data));
    php.stderr.on('data', data => console.log(data));
    php.on('close', (code) => {
        console.log(`php-fpm exited with code ${code}`);
        const end_dt = new Date().getTime();
        if (end_dt - start_dt > 1000) {
            // restart php-fpm
            setTimeout(() => start_php(), 2000);
        }
    });
})();
let nginx_v = spawnSync('nginx', ['-v']);
nginx_v = nginx_v.stdout.toString().trim() || nginx_v.stderr.toString().trim();
const php_v = execSync('php -v').toString().trim();
const mysql_v = execSync('mysql -V').toString().trim();
const index =
`
<!DOCTYPE html> 
<html> 
<head> 
<meta charset="utf-8" /> 
<title>LEMP in docker test</title> 
<style> 
	body{ text-align:center} 
	.version{ margin:0 auto; border:1px solid #F00} 
</style> 
</head> 
<body> 
    lemp versions:
    <div class="version">    
    ${nginx_v}<br>
    ${php_v}<br>
    ${mysql_v}
	</div> 
	<br>
	<?php echo phpinfo(); ?>
</body> 
</html> 
`;
fs.writeFileSync('/var/www/index.php', index);
(function start_nginx() {
    const start_dt = new Date().getTime();
    const nginx = exec( `nginx` );
    nginx.stdout.on('data', data => console.log(data));
    nginx.stderr.on('data', data => console.log(data));
    nginx.on('close', (code) => {
        console.log(`nginx exited with code ${code}`);
        const end_dt = new Date().getTime();
        if (end_dt - start_dt > 3600 * 1000) {
            // restart nginx
            setTimeout(() => start_nginx(), 1000);
        }
    });
})();