<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Untitled Document</title>
</head>

<body>
<script type="text/javascript" src="http://code.jquery.com/jquery-1.4.2.min.js"></script>
<script type="text/javascript" src="fancybox/jquery.fancybox-1.3.1.pack.js"></script>
<script type="text/javascript" src="fancybox/jquery.easing-1.3.pack.js"></script>
<script type="text/javascript" src="fancybox/jquery.mousewheel-3.0.2.pack.js"></script>
<link rel="stylesheet" href="fancybox/jquery.fancybox-1.3.1.css" type="text/css" media="screen" />
<div align="left">
  <script type="text/javascript">
$(document).ready(function() {

	/* This is basic - uses default settings */
	
	$("a#single_image").fancybox({

	});

	/* Using custom settings */
	
	$("a#inline").fancybox({
		'hideOnContentClick': true
	});

	/* Apply fancybox to multiple items */
	
	$("a.group").fancybox({
		'transitionIn'	:	'elastic',
		'transitionOut'	:	'elastic',
		'speedIn'		:	600, 
		'speedOut'		:	200, 
		'overlayShow'	:	false
	});
	
});

</script>
  <a id="single_image" href="whats_the_catch.html">
    <img src="images/catch.jpg" alt="" border="0" class="img_pad" /></a>
</div>
</body>
</html>
