<?php 

/**
 * Template Name: With Sidebar
 */

get_header(); ?>

    <div class="spacer clear line"></div>
    
    <div class="m whitecontainer">
    
      <div class="leftcol largecol">
      
     <?php if (have_posts()) : ?>
               <?php while (have_posts()) : the_post(); ?>    
               
               <h1><?php the_title(); ?></h1>
               
               <?php the_content(); ?>
               
               <?php endwhile; ?>
     <?php endif; ?>
           
      </div>
      
      <div class="rightcol smallcol">
      
		<?php
        
            $quote =  get_post_meta($post->ID, 'page-quote', true);
			
			if ( $quote !== '' ) {
			
            $quote = explode("/", $quote);			
                            
        ?>
      
      	<div class="internalquote">
        	
            <?php 
			
				$image =  get_post_meta($post->ID, 'quote-image', true);
				
				if ( $image !== '' ) {
			
			?>
            
            <img src="<?php echo $image; ?>" />
            
            <?php } ?>
            
            <p><?php echo  $quote[0]; ?></p>
            <p class="who"><?php echo $quote[1]; ?></p>
            
        </div>
        
        <?php } ?>

<?php if ( is_page('faqs')) {
      ?>
        <img src="<?php bloginfo('template_directory'); ?>/images/register.jpg" />
<?php } ?>        
        <br /><br />
      
      </div>
      
      <div class="clear"></div>
      
      </div>
    
    <!--- END WHITECONTAINER --->


<?php get_footer(); ?>
