<?php 

/**
 * Template Name: Full Width
 */

get_header(); ?>

    <div class="spacer clear line"></div>
    
    <div class="m whitecontainer">
    
      <div class="leftcol" style="width:100%;">
      
     <?php if (have_posts()) : ?>
               <?php while (have_posts()) : the_post(); ?>    
               
               <!-- <h1><?php the_title(); ?></h1> -->
               
               <?php the_content(); ?>
               
               <?php endwhile; ?>
     <?php endif; ?>
           
      </div>
      
      <div class="clear"></div>
      
      </div>
    
    <!--- END WHITECONTAINER --->


<?php get_footer(); ?>
