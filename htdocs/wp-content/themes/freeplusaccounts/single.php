<?php get_header(); ?>
    
    <div class="spacer clear line"></div>
    
    <div class="m whitecontainer">
    
      <div class="leftcol largecol">
    
            <p><a href="javascript:history.back(1)">Back</a></p>
        
            <?php if ( have_posts() ) : while ( have_posts() ) : the_post(); ?>
            <div class="post">
            
                <h1><?php the_title(); ?></h1>
                <p class="date"><?php the_time('F jS, Y'); ?></p>
                
                <?php the_content(); ?>
        
            </div>
            
				<br />
                <p class="postmetadata"><em>Posted in:</em> <?php the_category(', '); ?></p>
                
				<?php comments_template( '', true ); ?>
            
            <?php endwhile; else: ?>
            
                <p>Sorry, no posts matched your criteria.</p>
                
            <?php endif; ?>

        </div>
        
      <div class="rightcol smallcol categoryside listfix">
      	
        <ul>
      		<?php dynamic_sidebar( 'news-side' ); ?>
      	</ul>
        
      </div>
      
        <div class="clear"></div>
      
	</div>
    
    <div class="clear"></div>
    
    <!--- END WHITECONTAINER --->

<?php get_footer(); ?>