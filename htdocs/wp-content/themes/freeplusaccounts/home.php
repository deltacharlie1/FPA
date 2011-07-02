<?php 

/**
 * Template Name: Home Page
 */

get_header(); ?>

<?php
	
	// HOME BANNER
	include (TEMPLATEPATH . '/inc_banner.php');

?>

    
    <div class="spacer clear"></div>
    
    <div class="m whitecontainer">
    
      <div class="leftcol">
      
     <?php if (have_posts()) : ?>
               <?php while (have_posts()) : the_post(); ?>    
               
               <?php the_content(); ?>
               
               <?php endwhile; ?>
     <?php endif; ?>
      
      </div>
      
      <div class="rightcol">
      
        <div class="listfix">
               
		<img alt="Free, Easy, Secure" class="break" src="/wp-content/themes/freeplusaccounts/images/title-free.jpg" /><ul>			<div class="textwidget">How can we afford to make it free?<br/>Read More ...</div>
		</ul><img alt="Free, Easy, Secure" class="break" src="/wp-content/themes/freeplusaccounts/images/title-easy.jpg" /><ul>			<div class="textwidget">Why is it so easy to use?<br/>Read More ...</div>

		</ul><img alt="Free, Easy, Secure" class="break" src="/wp-content/themes/freeplusaccounts/images/title-secure.jpg" /><ul>			<div class="textwidget">What makes it so secure?<br/>Read More ...</div>
		</ul>        
 
        </div>        
      
      </div>
      
      <div class="clear"></div>
      
      </div>

<?php
	
	// HOME FOOTER ( less than 5 min... )
	include (TEMPLATEPATH . '/inc_footer_home.php');

?>

<?php get_footer(); ?>
