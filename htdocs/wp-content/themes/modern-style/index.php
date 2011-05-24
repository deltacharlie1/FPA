<?php get_header(); ?>
			<div id="content">	
                <?php include_once(TEMPLATEPATH . '/topbanner.php'); ?>	
				<?php if (have_posts()) : ?>	
					<?php while (have_posts()) : the_post(); ?>
					
					<div <?php post_class('clearfix'); ?> id="post-<?php the_ID(); ?>">
						<h2 class="title"><a href="<?php the_permalink() ?>" rel="bookmark" title="Permanent Link to <?php the_title_attribute(); ?>"><?php the_title(); ?></a></h2>
						<div class="postdate">
                            <span><?php the_time('F jS, Y') ?></span> 
                            <span><?php comments_popup_link('No Comments', '1 Comment', '% Comments'); ?></span> <?php edit_post_link('Edit', '', ' '); ?>
                        </div>
		
						<div class="entry">
                            <?php if ( function_exists("has_post_thumbnail") && has_post_thumbnail() ) { the_post_thumbnail(array(200,160), array("class" => "alignleft post_thumbnail")); } ?>
							<?php the_content(''); ?>
                            <div class="readmorecontent">
								<a class="readmore" href="<?php the_permalink() ?>" rel="bookmark" title="Permanent Link to <?php the_title_attribute(); ?>">Read More &raquo;</a>
							</div>
						</div>
					</div><!--/post-<?php the_ID(); ?>-->
				
				<?php endwhile; ?>
				<div class="navigation">
            		<?php if(function_exists('wp_pagenavi')) { wp_pagenavi(); } else { ?>
            		<div class="alignleft"><?php next_posts_link('&laquo; Older Entries') ?></div>
            		<div class="alignright"><?php previous_posts_link('Newer Entries &raquo;') ?></div>
            		<?php } ?>
            	</div>
				<?php else : ?>
					<h2 class="center">Not Found</h2>
					<p class="center">Sorry, but you are looking for something that isn't here.</p>
					<?php get_search_form(); ?>
			
				<?php endif; ?>
			</div>
        </div>
        <?php get_sidebar(); ?>
<?php get_footer(); ?>
