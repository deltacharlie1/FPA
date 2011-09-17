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
               
		<img alt="Free" class="break" src="/wp-content/themes/freeplusaccounts/images/title-free.jpg" /><ul>			<div id="freemore" class="textwidget">How can we afford to make it free?<br/>FreePlus Accounts has been developed by us for our own use.&nbsp;&nbsp;As such the only additional costs we have are those associated with making it avaialble to the public and we can absord those costs (and probably make a bit of money as well) by placing adverts on the different acocunting screens.</div>
		</ul><img alt="Easy" class="break" src="/wp-content/themes/freeplusaccounts/images/title-easy.jpg" /><ul>			<div id="easymore" class="textwidget">Why is it so easy to use?<br/>FreePlus Accounts is so easy to use because we've developed it to work as we would like it to work, not so as to suit our accountant!&nbsp;&nbsp;If, when using our system, we find that there is something we would like to do that we can't do then we just write a new program to enable us to do it!&nbsp;&nbsp;This approach means that FreePlus Accounts is intuitively straightforward for any reasonably competent business person.</div>
		</ul><img alt="Secure" class="break" src="/wp-content/themes/freeplusaccounts/images/title-secure.jpg" /><ul>			<div id= "securemore" class="textwidget">What makes it so secure?<br/>We value the security of our data as much as anyone.&nbsp;&nbsp;FreePlus Accounts runs on a secure server hosted in a highly secure, special purpose building with restricted access.&nbsp;&nbsp;All data that is displayed on your screens and that you enter is encrypted to the same level as the banks use and so no-one is going to be able to see your data.&nbsp;&nbsp;A standard policy of the server hosting solution that we use is to carry out continuous backups so that, in the event of any failure, we can always go back to the last good entry.</div>
		</ul>        
		</ul><img alt="Approved" class="break" src="/wp-content/themes/freeplusaccounts/images/title-approved.jpg" title="Institute of Certified Bookkeepers" /><ul><div id= "approvedmore" class="textwidget">The Institute of Certified Bookkeepers has tested and approved FreePlus Accounts for use by small businesses and sole traders.&nbsp;&nbsp;They were particularly impressed by the simplicity and ease of use of the system - read the full review <a href="#">here</a>.</div>
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
