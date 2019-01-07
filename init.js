#!/usr/bin/env node
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

(function start_php() {
    const start_dt = new Date().getTime();
    const php = exec( `php-fpm -F -O` );
    php.stdout.on('data', data => console.log(`php-fpm say: ${data}`));
    php.stderr.on('data', data => console.log(`php-fpm shout: ${data}`));
    php.on('close', (code) => {
        console.log(`php-fpm exited with code ${code}`);
        // const end_dt = new Date().getTime();
        // if (end_dt - start_dt > 1000) {
            // restart php-fpm
            setTimeout(() => start_php(), 2000);
        // }
    });
})();
const index_path = '/var/www/index.php';
if ( !fs.existsSync(index_path) ) {
    let nginx_v = spawnSync('nginx', ['-v']);
    nginx_v = nginx_v.stdout.toString().trim() || nginx_v.stderr.toString().trim();
    const php_v = execSync('php -v').toString().trim();
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
        </div> 
        <br>
        <?php echo phpinfo(); ?>
    </body> 
    </html> 
    `;
    fs.writeFileSync(index_path, index);
}

(function start_nginx() {
    const nginx = exec( `nginx` );
    nginx.stdout.on('data', data => console.log(`nginx say: ${data}`));
    nginx.stderr.on('data', data => console.log(`nginx shout: ${data}`));
    nginx.on('close', (code) => {
        console.log(`nginx exited with code ${code}`);
        // restart nginx
        setTimeout(() => start_nginx(), 1000);        
    });
})();