<?php 

/**
 * Template Name: Home Page (New)
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
               
               <h1><?php the_title(); ?></h1>
               
               <?php the_content(); ?>
               
               <?php endwhile; ?>
     <?php endif; ?>
      
      </div>
      
      <div class="rightcol">
      
        <div class="listfix">
        
			<?php dynamic_sidebar( 'home-side' ); ?>
        
        </div>        
      
      </div>
      
      <div class="clear"></div>
      
      </div>

<?php
	
	// HOME FOOTER ( less than 5 min... )
	include (TEMPLATEPATH . '/inc_footer_home.php');

?>

<?php get_footer(); ?>