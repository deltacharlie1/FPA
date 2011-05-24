<?php get_header(); ?>
    		<div id="content">	
            <?php include_once(TEMPLATEPATH . '/topbanner.php'); ?>	
    			<?php if (have_posts()) : while (have_posts()) : the_post(); ?>
    			<div class="post clearfix" id="post-<?php the_ID(); ?>">
    			<h2 class="title"><?php the_title(); ?></h2>
    				<div class="entry">
                        <?php if ( function_exists("has_post_thumbnail") && has_post_thumbnail() ) { the_post_thumbnail(array(300,225), array("class" => "alignleft post_thumbnail")); } ?>
    					<?php the_content('<p class="serif">Read the rest of this page &raquo;</p>'); ?>
    	
    					<?php wp_link_pages(array('before' => '<p><strong>Pages:</strong> ', 'after' => '</p>', 'next_or_number' => 'number')); ?>
    	
    				</div>
    			</div>
                <?php comments_template(); ?>
    			<?php endwhile; endif; ?>
    		<?php edit_post_link('Edit this entry.', '<p>', '</p>'); ?>
    		</div>
    	</div>
    
        <?php get_sidebar(); ?>
<?php get_footer(); ?>