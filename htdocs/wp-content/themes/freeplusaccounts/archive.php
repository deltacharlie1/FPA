<?php get_header(); ?>
    
    <div class="spacer clear line"></div>
    
    <div class="m whitecontainer">
    
      <div class="leftcol largecol">
    
            <h1>Archives</h1>
        
            <?php if ( have_posts() ) : while ( have_posts() ) : the_post(); ?>
            <div class="post">
            
                <h3><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h3>
                <p class="date"><?php the_time('F jS, Y'); ?></p>
                <p><?php the_excerpt(''); ?></p>
        
                <p class="postmetadata"><em>Posted in:</em> <?php the_category(', '); ?></p>
              
            </div>
            <?php endwhile; else: ?>
            
                <p>Sorry, no posts matched your criteria.</p>
                
            <?php endif; ?>
            
            <div class="pagination">
            
            	<?php posts_nav_link(' | ','',''); ?>
            
            </div>

        </div>
        
      <div class="rightcol smallcol categoryside listfix">
      	
        <ul>
      		<?php dynamic_sidebar( 'news-side' ); ?>
      	</ul>
        
      </div>
      
        <div class="clear"></div>
      
	</div>
    
    <div class="clear"></div>

<?php get_footer(); ?>