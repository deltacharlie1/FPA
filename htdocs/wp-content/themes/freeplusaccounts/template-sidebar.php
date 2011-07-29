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
               
               <!-- <h1><?php the_title(); ?></h1> -->
               
               <?php the_content(); ?>
               
               <?php endwhile; ?>
     <?php endif; ?>
           
      </div>
      
      <div class="rightcol smallcol">

<!--START MERCHANT:365ink from affiliatewindow.com.-->						  <a href="http://www.awin1.com/cread.php?s=254975&v=3466&q=122160&r=125207" target="_blank"><img src="http://www.awin1.com/cshow.php?s=254975&v=3466&q=122160&r=125207" border="0"></a>							<!--START MERCHANT:365ink from affiliatewindow.com.-->
<br/>
<!--START MERCHANT:merchant name Vistaprint from affiliatewindow.com.-->
			<a href="http://www.awin1.com/cread.php?s=75706&v=282&q=62496&r=125207"><img src="http://www.awin1.com/cshow.php?s=75706&v=282&q=62496&r=125207" border="0"></a>
			<!--END MERCHANT:merchant name Vistaprint from affiliatewindow.com-->

<br/>
<!--START MERCHANT:merchant name John Lewis from affiliatewindow.com.-->
			<a href="http://www.awin1.com/cread.php?s=135434&v=1203&q=84922&r=125207"><img src="http://www.awin1.com/cshow.php?s=135434&v=1203&q=84922&r=125207" border="0"></a>
			<!--END MERCHANT:merchant name John Lewis from affiliatewindow.com-->

<br/>      
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
        
        <img src="<?php bloginfo('template_directory'); ?>/images/register.jpg" />
        
        <br /><br />
      
      </div>
      
      <div class="clear"></div>
      
      </div>
    
    <!--- END WHITECONTAINER --->


<?php get_footer(); ?>
