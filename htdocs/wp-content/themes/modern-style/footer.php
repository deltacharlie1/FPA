
		</div><!--/container-->
			<div id="footer">
				Copyright &copy; <a href="<?php bloginfo('home'); ?>"><strong><?php bloginfo('name'); ?></strong></a> -  <?php bloginfo('description'); ?> <br />
                <div class="footer-credits">
                    Powered by <a href="http://wordpress.org/">WordPress</a> | <a href="http://flexithemes.com/themes/modern-style/">Modern Style</a> theme by <a href="http://flexithemes.com/">FlexiThemes</a>
                </div>
			</div><!--/footer-->
            
	</div><!--/wrapper-->
	<?php 
        wp_footer();
        echo get_theme_option("footer")  . "\n";
     ?>
    
</body>
</html>