<div class="span-8 last">
    <div id="subscriptions">
        <a href="<?php bloginfo('rss2_url'); ?>"><img src="<?php bloginfo('template_url'); ?>/images/rss.png" alt="Subscribe to RSS Feed" title="Subscribe to RSS Feed" /></a>		
		<?php if(get_theme_option('twitter') != '') { ?><a href="<?php echo get_theme_option('twitter'); ?>" title="<?php echo get_theme_option('twittertext'); ?>"><img src="<?php bloginfo('template_url'); ?>/images/twitter.png" title="<?php echo get_theme_option('twittertext'); ?>" alt="<?php echo get_theme_option('twittertext'); ?>"  /></a><?php } ?>
    </div>
	<div id="sidebar">
        <ul>
            <li id="search">
				<?php get_search_form(); ?>
			</li>
        </ul>
        <?php
		if(get_theme_option('socialnetworks') != '') {
			?>
    			<div class="addthis_toolbox">   
    			    <div class="custom_images">
    			            <a class="addthis_button_twitter"><img src="<?php bloginfo('template_directory'); ?>/images/socialicons/twitter.png" width="32" height="32" alt="Twitter" /></a>
    			            <a class="addthis_button_delicious"><img src="<?php bloginfo('template_directory'); ?>/images/socialicons/delicious.png" width="32" height="32" alt="Delicious" /></a>
    			            <a class="addthis_button_facebook"><img src="<?php bloginfo('template_directory'); ?>/images/socialicons/facebook.png" width="32" height="32" alt="Facebook" /></a>
    			            <a class="addthis_button_digg"><img src="<?php bloginfo('template_directory'); ?>/images/socialicons/digg.png" width="32" height="32" alt="Digg" /></a>
    			            <a class="addthis_button_stumbleupon"><img src="<?php bloginfo('template_directory'); ?>/images/socialicons/stumbleupon.png" width="32" height="32" alt="Stumbleupon" /></a>
    			            <a class="addthis_button_favorites"><img src="<?php bloginfo('template_directory'); ?>/images/socialicons/favorites.png" width="32" height="32" alt="Favorites" /></a>
    			            <a class="addthis_button_more"><img src="<?php bloginfo('template_directory'); ?>/images/socialicons/more.png" width="32" height="32" alt="More" /></a>
    			    </div>
    			    <script type="text/javascript" src="http://s7.addthis.com/js/250/addthis_widget.js?pub=xa-4a65e1d93cd75e94"></script>
    			</div>
    			<?php
    		}
    	?>
		<?php if(get_theme_option('banners_125') != '') {
			?>
			<div style="text-align: center; margin-top: 5px;">
				<?php banners_125(); ?>
			</div>
		<?php } ?>
        
		<ul>
		  <?php if ( !function_exists('dynamic_sidebar') || !dynamic_sidebar() ) : ?>
				
                <?php wp_list_pages('title_li=<h2>Pages</h2>' ); ?>
				<li><h2><?php _e('Recent Posts'); ?></h2>
			     <ul>
					<?php wp_get_archives('type=postbypost&limit=5'); ?>  
                </ul>
				</li>
				
				<li><h2>Archives</h2>
					<ul>
					<?php wp_get_archives('type=monthly'); ?>
					</ul>
				</li>
				
				<li><h2>Calendar</h2>
					<?php get_calendar(); ?> 
				</li>
				
				<?php wp_list_categories('hide_empty=0&show_count=1&title_li=<h2>Categories</h2>'); ?>
				
				<li id="tag_cloud"><h2>Tags</h2>
					<?php wp_tag_cloud('largest=16&format=flat&number=20'); ?>
				</li>
				
				<?php wp_list_bookmarks(); ?>
                
				<li><h2>Meta</h2>
					<ul>
						<?php wp_register(); ?>
						<li><?php wp_loginout(); ?></li>
						<li><a href="http://gmpg.org/xfn/"><abbr title="XHTML Friends Network">XFN</abbr></a></li>
						<li><a href="http://wordpress.org/" title="Powered by WordPress, state-of-the-art semantic personal publishing platform.">WordPress</a></li>
						<?php wp_meta(); ?>
					</ul>
				</li>
			<?php endif; ?>
		</ul>
	</div>
</div>
