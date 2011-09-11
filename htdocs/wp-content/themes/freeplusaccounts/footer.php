    
    <?php
	
		
	
		$greenoption = get_post_meta($post->ID, 'green-option', true);
		
		if ( $greenoption !== 'hide' ) {
			
	
	?>
    
    <div class="footer-b">
            
      <div class="m">
        
			<?php 
			
			
				if ( $greenoption == 'green1' ) { 
			
					dynamic_sidebar( 'option-one' );
				
				} else if ( $greenoption == 'green2' ) {
			
					dynamic_sidebar( 'option-two' );
				
				} else {
				
				?>
                
        
        	<h3>Latest News Posts</h3>
            
            <div class="listfix">
            
            	<ul>
					<?php
					query_posts($query_string . '&posts_per_page=3');
					if ( have_posts() ) : while ( have_posts() ) : the_post(); ?>
                	<li>
                    	<h4><a href="<?php the_permalink(); ?>"><?php the_title(); ?> // <?php the_date(); ?></a></h4>
                        <?php the_excerpt(); ?>
                    </li>   
                    <?php endwhile; else: ?>
                        Sorry, no posts matched your criteria.
                    <?php endif; ?>
                </ul>
                
                <div class="clear"></div>
            
            </div>
            
			<div class="clear"></div>
            
			<?php }  ?>

		</div>
                
    </div>
    
	<div class="clear"></div>
        
    <?php }  ?>
        
	<div class="clear"></div>

    <div class="footer">
    
      <div class="m">
      
      <div class="logo"><a href="<?php echo get_site_url(); ?>" title="Free Plus Accounts"><img src="<?php bloginfo('template_directory'); ?>/images/logo-footer.jpg" alt="Free Plus Accounts" /></a></div>
      
      <div class="footer-links">
      
          <div class="listfix">
          
				<?php wp_nav_menu( array( 'theme_location' => 'footer' ) ); ?>
          
          </div>
      
      <p>&copy; <?php echo date("Y"); ?> Free Plus Accounts, All Rights Reserved</p>
      
      <p class="credits"><a href="http://www.logicdesign.co.uk" title="Web Design">Web Design</a> by <a href="http://www.logicdesign.co.uk" title="Web Design">Logic Design</a></p>
      
      </div>
      
      <div class="social">
      		
          <script type="text/javascript"> Cufon.now(); </script>
            
          <div class="addthis_toolbox addthis_default_style " style="width:200px;">
              <a class="addthis_button_tweet"></a>
              <a class="addthis_counter addthis_pill_style" style="margin-top:0px;float:right;"></a>

<!-- GeoTrust QuickSSL [tm] Smart Icon tag. Do not edit. -->
              <div style="float:left;padding-top:8px;"><SCRIPT LANGUAGE="JavaScript" TYPE="text/javascript" SRC="//smarticon.geotrust.com/si.js"></SCRIPT></div>
              <!-- <div style="float:right;padding-top:5px;"><img src="/images/icb_logo.png" width="66" height="64"/></div> -->

 <!-- end GeoTrust Smart Icon tag -->    
          </div>
          <script type="text/javascript" src="http://s7.addthis.com/js/250/addthis_widget.js#pubid=xa-4d9adfb82ccdc016"></script>
          
      </div>
      
      <div class="clear"></div>
      
      </div>
    
    </div>
	<script type="text/javascript">
        swfobject.registerObject("FlashID");
    </script>
    
    <?php wp_footer(); ?>
    
</body>
</html>
