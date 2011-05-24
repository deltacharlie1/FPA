<?php get_header(); ?>
    	<div id="content">
        <?php include_once(TEMPLATEPATH . '/topbanner.php'); ?>	
    	<?php if (have_posts()) : ?>
    
    		<h2 class="pagetitle">Search Results</h2>
    
    		<?php while (have_posts()) : the_post(); ?>
    
    			<div <?php post_class('post clearfix') ?>>
    			<h2 class="title" id="post-<?php the_ID(); ?>"><a href="<?php the_permalink() ?>" rel="bookmark" title="Permanent Link to <?php the_title_attribute(); ?>"><?php the_title(); ?></a></h2>
				<div class="postdate">
                    <span><?php the_time('F jS, Y') ?></span> 
                    <span><?php comments_popup_link('No Comments', '1 Comment', '% Comments'); ?></span> <?php edit_post_link('Edit', '', ' '); ?>
                </div>

				<div class="entry">
                    <?php if ( function_exists("has_post_thumbnail") && has_post_thumbnail() ) { the_post_thumbnail(array(200,160), array("class" => "alignleft post_thumbnail")); } ?>
					<?php the_excerpt() ?>
                    <div class="readmorecontent">
						<a class="readmore" href="<?php the_permalink() ?>" rel="bookmark" title="Permanent Link to <?php the_title_attribute(); ?>">Read More &raquo;</a>
					</div>
				</div>
                
				<div class="postmeta">Posted in <?php the_category(', ') ?> | <?php the_tags('Tags: ', ', ', ''); ?> </div>
    			</div>
    
    		<?php endwhile; ?>
    
    		<div class="navigation">
				<?php if(function_exists('wp_pagenavi')) { wp_pagenavi(); } else { ?>
				<div class="alignleft"><?php next_posts_link('&laquo; Older Entries') ?></div>
				<div class="alignright"><?php previous_posts_link('Newer Entries &raquo;') ?></div>
				<?php } ?>
			</div>
    
    	<?php else : ?>
    
    		<h2 class="center">No posts found. Try a different search?</h2>
    		<?php get_search_form(); ?>
    
    	<?php endif; ?>
    
    		</div>
    	</div>
    
        <?php get_sidebar(); ?>
<?php get_footer(); ?>