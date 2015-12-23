<!DOCTYPE html> 
<html> 
<head> 
<meta charset="utf-8" /> 
<title>LEMP in docker test</title> 
<style> 
	body{ text-align:center} 
	.div{ margin:0 auto; width:400px; height:25px; border:1px solid #F00} 
</style> 
</head> 
<body> 
	<div class="div"> 
		<?php echo "This is docker lemp(ubuntu14.04 + nginx1.9.9 + php7 + mariadb10.1) env" ?>
	</div> 
	<br>
	<?php echo phpinfo(); ?>
</body> 
</html> 



