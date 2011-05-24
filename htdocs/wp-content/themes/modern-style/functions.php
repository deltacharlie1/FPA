<?php
if ( function_exists('register_sidebar') ) {
	register_sidebar(array(
        'before_widget' => '<li id="%1$s" class="widget %2$s">',
        'after_widget' => '</li>',
        'before_title' => '<h2 class="widgettitle">',
        'after_title' => '</h2>',
    ));
}

$themename = "Modern Style";
$shortname = str_replace(' ', '_', strtolower($themename));

function get_theme_option($option)
{
	global $shortname;
	return stripslashes(get_option($shortname . '_' . $option));
}

$options = array (
			
	array("type" => "open"),
    
	array(	"name" => "Sidebar over header?",
			"desc" => "If checked, the sidebar will start over header as in default. Unchecked will move the sidebar below header.",
			"id" => "sidebar_over_header",
			"std" => "true",
			"type" => "checkbox"),
            
    array(	"name" => "Logo Image",
		"desc" => "Enter the full url to your logo image. You can use the Media menu to <a href='" . get_bloginfo('url') ."/wp-admin/media-new.php'>upload your logo image</a> and get File URL. Leave it blank if you don't want to use a logo image.",
		"id" => "logo",
		"std" => "",
		"type" => "text"),
        
    array(	"name" => "Favicon",
		"desc" => "Enter the full url to your favicon file. You can use the Media menu to <a href='" . get_bloginfo('url') ."/wp-admin/media-new.php'>upload your favicon file</a> and get File URL. Leave it blank if you don't want to use a favicon.",
		"id" => "favicon",
		"std" => "",
		"type" => "text"),
        
    array("name" => "Top Banner (468x60)",
			"desc" => "Header banner code. Shown in all pages before posts. You may use any html code here, including your 468x60 px Adsense code.",
            "id" => "topbanner",
            "type" => "textarea",
			"std" => ""
        ),
			
	array(	"name" => "Sidebar 125x125 banners",
		"desc" => "Add your 125x125 banners here. You can add unlimited ads. Each new banner should be in new line with using the following format: <br/>http://anydomain.com/banner.gif, http://anydomain.com/link_url.html",
        "id" => "banners_125",
        "type" => "textarea",
		"std" =>  ""
		),
        	
    array(	"name" => "Twitter",
			"desc" => "Enter your twitter account full url here, like http://twitter.com/FlexiThemes. Leave it blank if you don't use Twitter",
			"id" => "twitter",
			"std" => "#",
			"type" => "text"),
			
	array(	"name" => "Twitter Text",
			"desc" => "The title texton mouse over.",
			"id" => "twittertext",
			"std" => "Follow me on Twitter!",
			"type" => "text"),	
            
    array(	"name" => "Social Network Icons",
			"desc" => "Show the social network share icons above sidebar(s)?",
			"id" => "socialnetworks",
			"std" => "true",
			"type" => "checkbox"),
	
	array(	"name" => "Head Script(s)",
		"desc" => "The content of this box will be added immediately before &lt;/head&gt; tag. Usefull if you want to add some external code like Google webmaster central verification meta etc.",
        "id" => "head",
        "type" => "textarea"	
		),
		
	array(	"name" => "Footer Script(s)",
		"desc" => "The content of this box will be added immediately before &lt;/body&gt; tag. Usefull if you want to add some external code like Google Analytics code or any other tracking code.",
        "id" => "footer",
        "type" => "textarea"	
		),
					
	array(	"type" => "close")
	
);

function mytheme_add_admin() {
    global $themename, $shortname, $options;
	
    if ( $_GET['page'] == basename(__FILE__) ) {
        if ( $_REQUEST['action'] == 'save') {
            foreach ($options as $value) {
                update_option( $shortname . '_' . $value['id'], $_REQUEST[ $shortname . '_' . $value['id'] ] ); 
            }
            echo '<meta http-equiv="refresh" content="0;url=themes.php?page=functions.php&saved=true">';
            exit();
        }
    }
    add_theme_page($themename." Options", "".$themename." Theme Options", 'edit_themes', basename(__FILE__), 'mytheme_admin');
}

function mytheme_admin_init() {

    global $themename, $shortname, $options;
    
    $get_theme_options = get_theme_option('options');
    if($get_theme_options != 'yes') {
    	foreach ($options as $value) {
         	update_option( $shortname . '_' . $value['id'],  $value['std'] ); 
		}
    	update_option($shortname . '_options', 'yes');
    }
}

function mytheme_admin() {

    global $themename, $shortname, $options;

    if ( $_REQUEST['saved'] ) echo '<div id="message" class="updated fade"><p><strong>'.$themename.' settings saved.</strong></p></div>';
    
?>
<div class="wrap">
<h2><?php echo $themename; ?> Theme Options</h2>
<div style="border-bottom: 1px dotted #000; padding-bottom: 10px; margin: 10px;">Leave any field blank if you don't want it to be displayed.</div>
<form method="post">



<?php foreach ($options as $value) { 
    $value['id_id'] = $shortname . "_" . $value['id'];;
	switch ( $value['type'] ) {
	
		case "open":
		?>
        <table width="100%" border="0" style=" padding:10px;">
		
        
        
		<?php break;
		
		case "close":
		?>
		
        </table><br />
        
        
		<?php break;
		
		case "title":
		?>
		<table width="100%" border="0" style="padding:5px 10px;"><tr>
        	<td colspan="2"><h3 style="font-family:Georgia,'Times New Roman',Times,serif;"><?php echo $value['name']; ?></h3></td>
        </tr>
                
        
		<?php break;

		case 'text':
		?>
        
        <tr>
            <td width="20%" rowspan="2" valign="middle"><strong><?php echo $value['name']; ?></strong></td>
            <td width="80%"><input style="width:100%;" name="<?php echo $value['id_id']; ?>" id="<?php echo $value['id_id']; ?>" type="<?php echo $value['type']; ?>" value="<?php echo get_theme_option( $value['id'] ); ?>" /></td>
        </tr>

        <tr>
            <td><small><?php echo $value['desc']; ?></small></td>
        </tr><tr><td colspan="2" style="margin-bottom:5px;border-bottom:1px dotted #000000;">&nbsp;</td></tr><tr><td colspan="2">&nbsp;</td></tr>

		<?php 
		break;
		
		case 'textarea':
		?>
        
        <tr>
            <td width="20%" rowspan="2" valign="middle"><strong><?php echo $value['name']; ?></strong></td>
            <td width="80%"><textarea name="<?php echo $value['id_id']; ?>" style="width:100%; height:140px;"  cols="" rows=""><?php echo get_theme_option( $value['id'] ); ?></textarea></td>
            
        </tr>

        <tr>
            <td><small><?php echo $value['desc']; ?></small></td>
        </tr><tr><td colspan="2" style="margin-bottom:5px;border-bottom:1px dotted #000000;">&nbsp;</td></tr><tr><td colspan="2">&nbsp;</td></tr>

		<?php 
		break;
		
		case 'select':
		?>
        <tr>
            <td width="20%" rowspan="2" valign="middle"><strong><?php echo $value['name']; ?></strong></td>
            <td width="80%">
				<select style="width:240px;" name="<?php echo $value['id_id']; ?>" id="<?php echo $value['id_id']; ?>">
					<?php 
						foreach ($value['options'] as $option) { ?>
						<option value="<?php echo $option['value']; ?>" <?php if ( get_theme_option( $value['id'] ) == $option['value']) { echo ' selected="selected"'; } ?>><?php echo $option['title']; ?></option>
						<?php } ?>
				</select>
			</td>
       </tr>
                
       <tr>
            <td><small><?php echo $value['desc']; ?></small></td>
       </tr><tr><td colspan="2" style="margin-bottom:5px;border-bottom:1px dotted #000000;">&nbsp;</td></tr><tr><td colspan="2">&nbsp;</td></tr>

		<?php
        break;
            
		case "checkbox":
		?>
            <tr>
            <td width="20%" rowspan="2" valign="middle"><strong><?php echo $value['name']; ?></strong></td>
                <td width="80%"><?php if(get_theme_option($value['id'])){ $checked = "checked=\"checked\""; }else{ $checked = ""; } ?>
                        <input type="checkbox" name="<?php echo $value['id_id']; ?>" id="<?php echo $value['id_id']; ?>" value="true" <?php echo $checked; ?> />
                        </td>
            </tr>
                        
            <tr>
                <td><small><?php echo $value['desc']; ?></small></td>
           </tr><tr><td colspan="2" style="margin-bottom:5px;border-bottom:1px dotted #000000;">&nbsp;</td></tr><tr><td colspan="2">&nbsp;</td></tr>
            
        <?php 		break;
	
 
} 
}
?>

<!--</table>-->

<p class="submit">
<input name="save" type="submit" value="Save changes" />    
<input type="hidden" name="action" value="save" />
</p>
</form>

<?php
}
mytheme_admin_init();

add_action('admin_menu', 'mytheme_add_admin');

function banners_125()
{
	 $option = get_theme_option('banners_125');
     if($option) {
         $values = explode("\n", $option);
    	 if(is_array($values)) {
    	 	foreach ($values as $item) {
    		 	$ad = explode(',', $item);
    		 	$banner = trim($ad['0']);
    		 	$url = trim($ad['1']);
    		 	if(!empty($banner) && !empty($url)) {
    		 		echo "<a href=\"$url\" target=\"_new\"><img class=\"banner125\" src=\"$banner\" alt=\"\" title=\"\" /></a> \n";
    		 	}
    		 }
    	 }
     }
}

if ( function_exists("add_theme_support") ) { add_theme_support("post-thumbnails"); } 
?>
