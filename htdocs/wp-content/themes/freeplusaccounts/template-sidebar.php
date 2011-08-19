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
<iframe src="https://rcm-uk.amazon.co.uk/e/cm?t=freeacco-21&o=2&p=27&l=qs1&f=ifr" width="180" height="150" frameborder="0" scrolling="no"></iframe>
<br/>
<script type="text/javascript"><!--
google_ad_client = "pub-8735612401703713";
/* freeplus1 */
google_ad_slot = "4656407131";
google_ad_width = 160;
google_ad_height = 600;
//-->
</script>
<script type="text/javascript"
src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
</br/>
<!--START MERCHANT:365ink from affiliatewindow.com.-->						  <a href="http://www.awin1.com/cread.php?s=254975&v=3466&q=122160&r=125207" target="_blank"><img src="http://www.awin1.com/cshow.php?s=254975&v=3466&q=122160&r=125207" border="0"></a>							<!--START MERCHANT:365ink from affiliatewindow.com.-->
<br/>
<!--START MERCHANT:merchant name Vistaprint from affiliatewindow.com.-->
			<a href="http://www.awin1.com/cread.php?s=75706&v=282&q=62496&r=125207"><img src="http://www.awin1.com/cshow.php?s=75706&v=282&q=62496&r=125207" border="0"></a>
			<!--END MERCHANT:merchant name Vistaprint from affiliatewindow.com-->

<br/>
      </div>
      
      <div class="clear"></div>
      
      </div>
    
    <!--- END WHITECONTAINER --->


<?php get_footer(); ?>
