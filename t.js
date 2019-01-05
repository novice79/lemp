const fs = require('fs');
const { spawn, spawnSync, exec, execSync } = require('child_process');
let nginx_v = spawnSync('nginx',['-v']);
nginx_v = nginx_v.stdout.toString().trim() || nginx_v.stderr.toString().trim();
const php_v = execSync('php -v').toString().trim();
const mysql_v = execSync('mysql -V').toString().trim();
// console.log(nginx_v);

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
// console.log(index);
fs.writeFileSync('index.html', index);