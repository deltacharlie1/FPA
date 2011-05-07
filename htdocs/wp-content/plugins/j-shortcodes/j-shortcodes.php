<?php
/*
Plugin Name: J Shortcodes
Plugin URI: http://www.jshortcodes.com/
Version: 1.405
Author: Gleb Esman, http://www.jshortcodes.com/
Author URI: http://www.jshortcodes.com/
Description: Collection of useful shortcodes to create custom column layouts, add custom buttons, content boxes, tabs, accordion, feature and call to action boxes. Pick any color or size for any element. Create sophisticated column layouts directly within any page, post or even sidebar widget. Check out <a href="http://www.jshortcodes.com/shortcodes/">J Shortcodes samples, demos and tutorials</a>.
*/

define('J_SHORTCODES_VERSION',  '1.405');

include (dirname(__FILE__) . '/j-include-all.php');

//---------------------------------------------------------------------------
// Plugins actions, hooks and filters
register_activation_hook   (__FILE__,                    'JAY__activated');

add_filter                 ('the_content',               'JAY__the_content',           10);
add_action                 ('init',                      'JAY__init',                  10);
add_action                 ('wp_head',                   'JAY__wp_head',               10);
add_action                 ('wp_head',                   'JAY__wp_head_custom_css',    999);    // Make it last
add_action                 ('admin_init',                'JAY__admin_init');
add_action                 ('admin_head',                'JAY__admin_head');
add_action                 ('admin_menu',                'JAY__admin_menu');

add_filter                 ('widget_text',               'do_shortcode');
add_filter                 ('plugin_row_meta',           'JAY__set_plugin_meta', 10, 2);
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
// Shortcodes
// [jbutton]
add_shortcode              ('jbuttonify',                'JAY__shortcode__jbuttonify');   // Experimental. Converts words on page to randomly colored and sized buttons.

add_shortcode              ('jbox',                      'JAY__shortcode__jbox');
add_shortcode              ('jbutton',                   'JAY__shortcode__jbutton');
add_shortcode              ('jcolumns',                  'JAY__shortcode__jcolumns');
add_shortcode              ('j-memberwing',              'JAY__shortcode__jmemberwing');
add_shortcode              ('jpage',                     'JAY__shortcode__jpage');
add_shortcode              ('jfeed',                     'JAY__shortcode__jfeed');
add_shortcode              ('jtabs',                     'JAY__shortcode__jtabs');
add_shortcode              ('jaccordion',                'JAY__shortcode__jaccordion');
add_shortcode              ('jgallery',                  'JAY__shortcode__jgallery');
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
// Globals
$g_theme_unavail_message = '<div align="center" style="border:1px solid red;margin:3px;padding:3px;font-size:11px;line-height:13px;background-color:#ffd;">Warning: "{THEME}" theme must be enabled via J-Shortcodes settings panel:<br />Wordpress Admin&nbsp;-&gt;&nbsp;J-Shortcodes&nbsp;-&gt;&nbsp;General Settings, before it could be used.</div>';
//---------------------------------------------------------------------------

//===========================================================================
// Initial activation code here such as: DB tables creation, storing initial settings.

function JAY__activated ()
{
   JAY__upgrade_js_options ();
}
//===========================================================================

//===========================================================================
// Initial activation code here such as: DB tables creation, storing initial settings.

function JAY__upgrade_js_options ()
{
   global   $g_JAY__config_defaults;
   // Initial set/update default options

   // Fresh blueprint
   $jay_default_options = $g_JAY__config_defaults;

   // Populate fresh blueprint with existing settings
   // This will overwrite default options with already existing options but leave new options (in case of upgrading to new version) untouched.
   $jay_settings = JAY__get_settings ();
   if (is_array ($jay_settings))
      {
      foreach ($jay_settings as $key=>$value)
         {
         if (isset($jay_default_options[$key]))
            {
            // Copy only matching keys. Renamed/move/migrated keys will be handled below.
            $jay_default_options[$key] = $value;
            }
         }
      }

   //------------------------------------------------------------------------
   // Renamed/modified.merged settings migration

   // Force-set proper version of plugin.
   $jay_default_options['j-shortcodes-version'] = J_SHORTCODES_VERSION;
   //------------------------------------------------------------------------

   // Repopulating DB with new meta
   update_option ('J-Shortcodes', $jay_default_options);

   return ($jay_default_options);
}
//===========================================================================

//===========================================================================
function JAY__init ()
{

   // Make sure jQuery is properly loaded.
   JAY__Load_Jquery (FALSE);

   $jay_settings = JAY__get_settings();

   if ($jay_settings['j-shortcodes-version'] != J_SHORTCODES_VERSION)
      {
      $jay_settings = JAY__upgrade_js_options ();
      }

   if (@$jay_settings['disable-wpautop'])
      {
      remove_filter              ('the_content',               'wpautop');
      remove_filter              ('the_excerpt',               'wpautop');
      }
}
//===========================================================================

//===========================================================================
function JAY__the_content ($content="")
{
   // Strip <p> ... </p> around [j...] tags, fixing wpautop legacy.
   $content = preg_replace ('@<p>\s*(\[/?j[^\]]+\])\s*</p>@', "$1", $content);
   return $content;
}
//===========================================================================

//===========================================================================
function JAY__set_plugin_meta ($links, $file)
{
   $plugin = plugin_basename(__FILE__);

   // create link
   if ($file == $plugin)
      {
      return
         array_merge (
            $links,
            array( sprintf( '<div><a style="border:1px solid #888;padding:1px 4px;background-color:#ffc;-moz-border-radius:7px; -webkit-border-radius: 7px; -khtml-border-radius: 7px; border-radius: 7px;" href="options-general.php?page=j-shortcodes-settings">%s</a></div>', __('Settings')))
            );
      }

   return $links;
}
//===========================================================================

//===========================================================================
function JAY__Load_Jquery ($is_admin)
{
   $jay_settings = JAY__get_settings();

   global $plugin_page;

   // Load only for non-admin pages or for admin pages belonging to J Shortcodes plugin. Otherwise - conflicts.
   if (!is_admin() || ($plugin_page == 'j-shortcodes-settings'))
      {
      // --------------------------------------
      // If jtabs, jaccordion are disabled - do not load Jquery UI
      // If jtabs, jaccordion and jgallery are disabled - do not do anything here.
      $load_jquery    = FALSE;
      $load_jquery_ui = FALSE;

      foreach ($jay_settings['jquery_themes'] as $theme_name => $val)
         {
         if ($val)
            {
            $load_jquery    = TRUE;
            $load_jquery_ui = TRUE;
            break;
            }
         }
      if (@$jay_settings['jgallery_enabled'])
         $load_jquery    = TRUE;

      if ($plugin_page == 'j-shortcodes-settings')
         {
         $load_jquery    = TRUE;
         $load_jquery_ui = TRUE;
         }
      // --------------------------------------

      if (!$load_jquery)
         return;

      $jquery_version      = "1.4.4";
      $jquery_ui_version   = "1.8.9";

      wp_deregister_script ('jquery');             // using wp_deregister_script() to disable the version that comes packaged with WordPress
      wp_register_script   ('jquery',           "http://ajax.googleapis.com/ajax/libs/jquery/{$jquery_version}/jquery.min.js");         // using wp_register_script() to register updated libraries (this example uses the CDN from Google but you can use any other CDN or host the scripts yourself)
      wp_enqueue_script    ('jquery');          // using wp_enqueue_script() to load the updated libraries

      if ($load_jquery_ui)
         {
         wp_deregister_script ('jquery-ui-core');
         wp_deregister_script ('jquery-ui-tabs');

         wp_register_script   ('jquery-ui-core',   "http://ajax.googleapis.com/ajax/libs/jqueryui/{$jquery_ui_version}/jquery-ui.min.js");

         wp_enqueue_script    ('jquery-ui-core');
         wp_enqueue_script    ('jquery-ui-tabs');
         wp_enqueue_script    ('jquery-ui-accordion');
         }
      }

}
//===========================================================================

//===========================================================================
function JAY__Get_Extra_Header_HTML ($is_admin)
{
   global $g_JAY__plugin_directory_url;
   $jay_settings = JAY__get_settings();

   // Force load stylesheet and .js
   $extra_html =<<<TTT
<link rel="stylesheet" type="text/css" href="{$g_JAY__plugin_directory_url}/css/jay.css" />
<script type="text/javascript" src="{$g_JAY__plugin_directory_url}/js/jay.js"></script>
TTT;

   if (@$jay_settings['jgallery_enabled'])
      {
      $extra_html .=<<<TTT
<link rel="stylesheet" type="text/css" href="{$g_JAY__plugin_directory_url}/galleryview/css/jquery.galleryview-3.0.css" />
<script type="text/javascript" src="{$g_JAY__plugin_directory_url}/galleryview/js/jquery.easing.1.3.js"></script>
<script type="text/javascript" src="{$g_JAY__plugin_directory_url}/galleryview/js/jquery.timers-1.2.js"></script>
<script type="text/javascript" src="{$g_JAY__plugin_directory_url}/galleryview/js/jquery.galleryview-3.0.min.js"></script>
TTT;
      }

   if (!isset($jay_settings['jquery_themes']) || !is_array($jay_settings['jquery_themes']))
      $jay_settings['jquery_themes'] = array ();

   foreach ($jay_settings['jquery_themes'] as $theme_name => $val)
      {
      if ($val || $is_admin)
         $extra_html .=<<<TTT
<link rel="stylesheet" type="text/css" href="{$g_JAY__plugin_directory_url}/css/jquery/{$theme_name}/jquery-ui-1.8.9.custom.css" />
TTT;
      }

   return $extra_html;
}
//===========================================================================

//===========================================================================
function JAY__wp_head ()
{
   echo JAY__Get_Extra_Header_HTML (FALSE);
}
//===========================================================================

//===========================================================================
function JAY__wp_head_custom_css ()
{
   global   $g_JAY__config_defaults;

   $jay_settings = JAY__get_settings ();
   if ($jay_settings['custom_css'] && $jay_settings['custom_css'] != $g_JAY__config_defaults['custom_css'])
      {
?>
<style type="text/css">
<!--
/* J shortcodes custom CSS code. http://www.jshortcodes.com */
<?php echo $jay_settings['custom_css']; ?>

-->
</style>

<?php
      }
}
//===========================================================================

//===========================================================================
function JAY__admin_init ()
{
   // Make sure jQuery is properly loaded.
   JAY__Load_Jquery (TRUE);
}
//===========================================================================

//===========================================================================
function JAY__admin_head ()
{
   echo JAY__Get_Extra_Header_HTML (TRUE);
}
//===========================================================================

//===========================================================================
function JAY__admin_menu ()
{
   global $g_JAY__plugin_directory_url;

   add_menu_page    (
      'J-Shortcodes General Settings',           // Page Title
      '<b>J</b>-Shortcodes',              // Menu Title - lower corner of admin menu
      'administrator',                          // Capability
      'j-shortcodes-settings',                  // handle
      'JAY__render_general_settings_page',      // Function
      $g_JAY__plugin_directory_url . '/J_icon_16x.png'         // Icon URL
      );

   add_submenu_page (
      'j-shortcodes-settings',                  // Parent
      'J-Shortcodes General Settings',           // Page Title
      '<span style="font-weight:bold;color:#087bf9;">&bull;</span>&nbsp;General Settings',                       // Menu Title
      'administrator',                          // Capability
      'j-shortcodes-settings',                  // Handle - First submenu's handle must be equal to parent's handle to avoid duplicate menu entry.
      'JAY__render_general_settings_page'       // Function
      );
}
//===========================================================================

//===========================================================================
function JAY__render_general_settings_page ()         { JAY__render_settings_page   ('general'); }
//===========================================================================

//===========================================================================
// Do admin panel business, assemble and output admin page HTML
function JAY__render_settings_page ($menu_page_name)
{
   if (isset ($_POST['button_update_jay_settings']))
      {
      JAY__update_settings ();
      echo <<<HHHH
<div align="center" style="background-color:#FFA;padding:5px;font-size:110%;border: 1px solid gray;margin:5px;">
Settings updated!
</div>
HHHH;
      }
   else if (isset($_POST['button_reset_jay_settings']))
      {
      JAY__reset_all_settings ();
      echo <<<HHHH
<div align="center" style="background-color:#FFA;padding:5px;font-size:110%;border: 1px solid gray;margin:5px;">
All settings reverted to all defaults
</div>
HHHH;
      }
   else if (isset($_POST['button_reset_partial_jay_settings']))
      {
      JAY__reset_partial_settings ();
      echo <<<HHHH
<div align="center" style="background-color:#FFA;padding:5px;font-size:110%;border: 1px solid gray;margin:5px;">
Settings on this page reverted to defaults
</div>
HHHH;
      }
   else if (isset($_POST['button_subscribe_to_js_notifications']))
      {
      JAY__SubscribeToAweber ($_POST['subscribe_email']);
      echo <<<HHHH
<div align="center" style="background-color:#FFA;padding:5px;font-size:110%;border: 1px solid gray;margin:5px;">
Thank you for subscribing to J-Shortcodes notifications. Confirmation email will be sent to <b>{$_POST['subscribe_email']}</b> shortly.
<br />Make sure to click on confirmation link to activate your subscription.
<br />If you will not receive an email within a few minutes - please check your spam folder.
</div>
HHHH;
      }


   // Output full admin settings HTML
   JAY__render_admin_page_html ($menu_page_name);
}
//===========================================================================

//===========================================================================
function JAY__shortcode__jbuttonify ($atts, $content="")
{
   $content = JAY__fix_content ($content);   // Fix bug (</p>...content...<p>) introduced by wpautop + 'add_shortcode' + condition where content is surrounded by empty lines.
   $content = JAY__strip_p_tags ($content);  // Strip <p> tags around content

   $colors           = array ('white', 'gray', 'darkgray', 'black', 'orange', 'red', 'green', 'blue', 'rosy', 'pink');
   $colors_idx_max   = count ($colors) - 1;
   $sizes            = array ('xsmall', 'small', 'medium', 'large', 'xlarge', 'xxlarge');
   $sizes            = array ('xsmall', 'small', 'medium', 'large');
   $sizes_idx_max    = count ($sizes) - 1;
   $roundness        = array ('yes', 'no');

   $words      = preg_split ("@[\s\n\r]+@s", strip_tags($content));

   $output_html = "";
   foreach ($words as $word)
      {
      if (trim($word))
         {
         $color_idx   = rand (0, $colors_idx_max);
         $size_idx    = rand (0, $sizes_idx_max);
         $rounded_idx = rand (0, 1);

         $output_html .= "[jbutton size='{$sizes[$size_idx]}' color ='{$colors[$color_idx]}' rounded='{$roundness[$rounded_idx]}']{$word}[/jbutton] ";
         }
      else
         $output_html .= $word;
      }

   return JAY__do_shortcode ($output_html);
}
//===========================================================================

//===========================================================================
// [jbutton] Shortcode:
// --------------------
//    [jbutton
//       size="xsmall|small|*medium|large|xlarge|xxlarge"
//       color="*white|gray|darkgray|black|orange|red|green|blue|rosy|pink"
//       rounded="yes|*no"
//       icon="*|yes|no|info|download|question|globe|add|doc|forum|pdf|love|http://link.to/my/icon.png"
//       link="*#|http://jump.on/click"
//       newpage="yes|*no"
//       a_css="*"
//       span_css="*"
//       ]
//       Button Text
//    [/jbutton]
//
// TIPS:
// -----
//    key="value1|value2"     - means key is mandatory and possible values for the key are 'value1' or 'value2'
//    key="value1|*value2"    - means if key is not specified, the default value used is 'value2'
//
// NOTES:
// ------
// -  For button size:
//    'xsmall'    - recommended icon size: 10x10px
//    'small'     - recommended icon size: 14x14px
//    'medium'    - recommended icon size: 16x16px
//    'large'     - recommended icon size: 20x20px
//    'xlarge'    - recommended icon size: 28x28px
//    'xxlarge'   - recommended icon size: 36x36px

function JAY__shortcode__jbutton ($atts, $content="")
{
   global $g_JAY__plugin_directory_url;

   extract (shortcode_atts (
      array(
         'size'         => 'medium',
         'color'        => 'white',
         'rounded'      => 'no',
         'icon'         => '',
         'link'         => '#',
         'newpage'      => 'no',       // if 'yes' - adds: target="_blank" to <a> tag.
         'border'       => '',         // thickness of border in pixels
         'a_css'        => '',         // Extra custom CSS styles for <a> tag. Ex:    "width:100px;font-weight:bold;"
         'span_css'     => '',         // Extra custom CSS styles for <span> tag. Ex: "width:100px;font-weight:bold;"
         ),
         $atts));

   $content = JAY__fix_content ($content);   // Fix bug (</p>...content...<p>) introduced by wpautop + 'add_shortcode' + condition where content is surrounded by empty lines.
   $content = JAY__strip_p_tags ($content);  // Strip <p> tags around content

   if (strpos ($icon, '/') !== FALSE)
      $icon_is_url = TRUE;
   else
      $icon_is_url = FALSE;

   $a_padding_num    = "";
   $span_css_style   = "";
   $is_icon          = "";

   //------------------------------------------
   $a_css_rules = array();
   if ($border)
      {
      $border_num = rtrim ($border, 'px;');
      $a_css_rules[] = "border-width:{$border_num}px;";
      }
   // This must be processed last.
   if ($a_css)
      {
      $a_css_custom = rtrim ($a_css, ';');
      $a_css_rules[] = $a_css_custom;
      }
   if (count($a_css_rules))
      {
      $a_css_extra = implode ($a_css_rules);
      $a_css_extra = "style=\"{$a_css_extra}\"";
      }
   else
      $a_css_extra = "";
   //------------------------------------------

   if ($newpage == 'yes' || $newpage==='1')
      $is_newpage = 'target="_blank"';
   else
      $is_newpage = '';

   if ($icon)
      {
      // icon="..." was specified
      $is_icon = "iconized";

      // Calculate padding
      switch ($size)
         {
         case 'xsmall'  :  $icon_size_prefix = "10x10"; break;
         case 'small'   :  $icon_size_prefix = "14x14"; break;
         case 'large'   :  $icon_size_prefix = "20x20"; break;
         case 'xlarge'  :  $icon_size_prefix = "28x28"; break;
         case 'xxlarge' :  $icon_size_prefix = "36x36"; break;

         case 'medium'  :
         default        :  $icon_size_prefix = "16x16"; break;
         }

      if ($icon_is_url)
         // Icon URL specified
         $icon_url = $icon;
      else
         $icon_url = $g_JAY__plugin_directory_url . "/images/{$icon_size_prefix}-{$icon}.png";

      $span_css_style = "style=\"background:url({$icon_url}) no-repeat 0 45%;{$span_css}\"";
      }


   if ($rounded == 'yes' || $rounded === '1')
      $is_rounded = 'rounded';
   else
      $is_rounded = '';

   $final_html = "<a {$a_css_extra} {$is_newpage} class=\"jbutton {$color} {$size} {$is_rounded} {$is_icon}\" href=\"{$link}\"><span {$span_css_style}>{$content}</span></a>";

   return JAY__do_shortcode ($final_html);
}
//===========================================================================

//===========================================================================
//    [jbox
//       width="*"
//       color="white|*gray|platinum|red|green|blue|yellow"
//       icon="*|http://link.to/icon.png"
//       title="*"
//       border="*1"
//       radius="*18"
//       shadow="*2"
//       jbox_css="*"
//       icon_css="*"
//       title_css="*"
//       content_css="*"
//       vgradient="*"
//    ] Jbox content text/html [/jbox]
//

function JAY__shortcode__jbox  ($atts, $content="")
{
   extract (shortcode_atts (
      array(
         'width'        => '',      // In pixels.
         'color'        => 'gray',
         'icon'         => '',
         'title'        => '',
         'border'       => '',      // thickness of border in pixels
         'radius'       => '',      // Default border radius = 18px.
         'shadow'       => '',      // Relative size of shadow in approx pixels
         'jbox_css'     => '',      // custom css code for outer box <div>. Ex: "background-color:#FFA;"
         'icon_css'     => '',      // custom css code for box. Ex: "background-color:#FFA;"
         'title_css'    => '',      // custom css code for box. Ex: "background-color:#FFA;"
         'content_css'  => '',      // custom css code for box. Ex: "background-color:#FFA;"
         'vgradient'    => '',      // Top to Bottom gradient, CSS colors definitions (including '#' if needed) separated by '|'. Ex: "#4f165a|#92764e"

         'link'         => '#',     // NOT SUPPORTED YET
         ),
         $atts));

   $content = JAY__fix_content ($content);   // Fix bug (</p>...content...<p>) introduced by wpautop + 'add_shortcode' + condition where content is surrounded by empty lines.
   $content = JAY__strip_p_tags ($content);  // Strip <p> tags around content

   $jbox_css_full    = '';
   $icon_css_full    = '';
   $title_css_full   = '';
   $content_css_full = '';

   $jbox_css_rules = array();
   if ($border)
      $jbox_css_rules[] = "border-width:" . rtrim($border, "px;") . "px;";
   if ($radius)
      {
      $radius_num = rtrim($radius, 'px;');
      $jbox_css_rules[] = "-moz-border-radius: {$radius_num}px;";
      $jbox_css_rules[] = "-webkit-border-radius: {$radius_num}px;";
      $jbox_css_rules[] = "-khtml-border-radius: {$radius_num}px;";
      $jbox_css_rules[] = "border-radius: {$radius_num}px;";
      }

   if ($width)
      $jbox_css_rules[] = "width:{$width}px;";

   if ($jbox_css)
      $jbox_css_rules[] = rtrim ($jbox_css, ';') . ';';

   if ($vgradient)
      {
      $colors = explode ('|', $vgradient);
      $colors[0] = rtrim ($colors[0], ';');
      $colors[1] = rtrim ($colors[1], ';');

      $jbox_css_rules[] = "background: -webkit-gradient(linear, left top, left bottom, from({$colors[0]}), to($colors[1]));";
      $jbox_css_rules[] = "background: -moz-linear-gradient(top, {$colors[0]}, {$colors[1]});";
      $jbox_css_rules[] = "filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='{$colors[0]}', endColorstr='{$colors[1]}');";
      }
   if ($shadow)
      {
      $shadow_num       = rtrim ($shadow, 'px;');
      if ($shadow_num)
         $shadow_blur_num  = $shadow_num+2;
      else
         $shadow_blur_num  = $shadow_num;
      $jbox_css_rules[] = "-webkit-box-shadow: {$shadow_num}px {$shadow_num}px {$shadow_blur_num}px rgba(0,0,0,.15);";
      $jbox_css_rules[] = "-moz-box-shadow: {$shadow_num}px {$shadow_num}px {$shadow_blur_num}px rgba(0,0,0,.15);";
      $jbox_css_rules[] = "box-shadow: {$shadow_num}px {$shadow_num}px {$shadow_blur_num}px rgba(0,0,0,.15);";
      }

   $icon_html = "";
   if ($icon)
      {
      if ($icon_css)
         $icon_css_full = 'style="' . rtrim($icon_css, ';') . ';"';

      $icon_html =<<<TTT
  <div {$icon_css_full} class="jbox-icon {$color}">
    <img src="{$icon}">
  </div>
TTT;
      }

   $title_html = "";
   if ($title)
      {
      if ($title_css)
         $title_css_full = 'style="' . rtrim($title_css, ';') . ';"';

      $title_html =<<<TTT
  <div {$title_css_full} class="jbox-title {$color}">{$title}</div>
TTT;
      }

   $content = JAY__trim_br ($content);

   if ($content_css)
      $content_css_full = 'style="' . rtrim($content_css, ';') . ';"';

   if (count($jbox_css_rules))
      $jbox_css_full = 'style="' . implode ($jbox_css_rules) . '"';
   else
      $jbox_css_full = '';
   $box_html = "<div class=\"jbox {$color}\" {$jbox_css_full}>{$icon_html}{$title_html}<div {$content_css_full} class=\"jbox-content\">{$content}</div></div>";

   return JAY__do_shortcode ($box_html);
}
//===========================================================================

//===========================================================================
// [jcolumns] shortcode.
/*
   [jcolumns
      model="*|M,N,P,Q..."
      halign="*left|center|right"
      valign="*top|middle|bottom"
      colclass="*"
      colgap="*12"
      colcss="*"
      stripbr="*yes|no"
      outbordercss="*"
      inbordercss="*"
      topbordercss="*"
      bottombordercss="*"
   ]
     ...column 1 content...
      [jcol/]
     ...column 2 content...
      [jcol/]
     ...column 3 content...
   [/jcolumns]
*/
// Notes:
//    -  model="111" - 3 equal columns 33% each; "1231" - 4 columns, 14%, 28%, 52%, 14%; "1111" - 4 columns 25% each, NOTE: when all columns need to be equal 'model=' param can be omitted.
//    -  '[jcol/]' - is the column separator
//    -  If 'model=' skipped - equal columns will result.
//    -  stripbr="1" - will strip one <br /> from the beginning and the end of each column's content. It is unsolicitly added by Wordpress. This is default.
//    -  stripbr="0" - will leave column content as is.

function JAY__shortcode__jcolumns  ($atts, $content="")
{
   extract (shortcode_atts (
      array(
         'model'        => '',      // comma-delimited relative units: "1,2,1,1". Could use as percentages: "20,40,20,20"
         'halign'       => 'left',
         'valign'       => 'top',   // top|middle|center|bottom
         'stripbr'      => 'yes',
         'colclass'     => '',
         'colgap'       => '12',    // gap between columns in pixels. Note: min:2 pixels
         'colcss'       => '',      // CSS rules to be applied to div of each column.
         'outbordercss' => '',      // Ex: "1px solid gray". Default:none. CSS of the outer left and right border.
         'inbordercss'  => '',      // Ex: "1px solid gray". Default:none. CSS of the border-separator in between columns.
         'topbordercss' => '',      // Ex: "1px solid gray". Default:none. CSS of the top border of columns.
         'bottombordercss' => '',   // Ex: "1px solid gray". Default:none. CSS of the bottom border of columns.
         ),
         $atts));

   $content = JAY__fix_content ($content);   // Fix bug (</p>...content...<p>) introduced by wpautop + 'add_shortcode' + condition where content is surrounded by empty lines.

   if ($colclass)
      $colclass_txt = "class=\"{$colclass}\"";
   else
      $colclass_txt = "";

   $colgap_num       = rtrim ($colgap, "px ;");
   if ($colcss)
      $colcss        = rtrim ($colcss, ';') . ';';
   $colcss_any       = "margin:0;padding:0;" . $colcss;

   if ($topbordercss)
      $topbordercss = "border-top:" . trim ($topbordercss, ';') . ';';

   if ($bottombordercss)
      $bottombordercss = "border-bottom:" . trim ($bottombordercss, ';') . ';';

   if ($valign == 'center')
      $valign = 'middle'; // Make it HTML-valid

   if ($valign == 'middle')
      $valign_css_rule = 'vertical-align:middle;';
   else
      $valign_css_rule = '';

   // Process column separators
   if (!$colgap_num || $colgap_num<2)
      $colgap_num = 2;
   $colgap_num1      = floor($colgap_num/2);       // 3
   $colgap_num2      = $colgap_num - $colgap_num1; // 4, if total 7.

   if ($outbordercss)
      {
      $outbordercss = rtrim ($outbordercss, ';') . ';';
      // To make first and last columns look gapped in the same way as inner columns, we must use inner gap params to calculate width of outside "border" columns.
      $left_gap_html    = "<td width=\"{$colgap_num2}\" style=\"margin:0;padding:0;border-left:{$outbordercss}{$topbordercss}{$bottombordercss}\"></td>";
      $right_gap_html   = "<td width=\"{$colgap_num1}\" style=\"margin:0;padding:0;border-right:{$outbordercss}{$topbordercss}{$bottombordercss}\"></td>";
      }
   else
      {
      $left_gap_html    = "";
      $right_gap_html   = "";
      }

   if ($inbordercss)
      {
      $inbordercss = rtrim ($inbordercss, ';') . ';';
      $inner_gap_html =  "<td width=\"{$colgap_num1}\" style=\"margin:0;padding:0;border-right:{$inbordercss}{$topbordercss}{$bottombordercss}\"></td>";
      $inner_gap_html .= "<td width=\"{$colgap_num2}\" style=\"margin:0;padding:0;{$topbordercss}{$bottombordercss}\"></td>";
      }
   else
      {
      $inner_gap_html =  "<td width=\"{$colgap_num1}\" style=\"margin:0;padding:0;{$topbordercss}{$bottombordercss}\"></td>";
      $inner_gap_html .= "<td width=\"{$colgap_num2}\" style=\"margin:0;padding:0;{$topbordercss}{$bottombordercss}\"></td>";
      }


   // "1,3,5" = 9 units, 3 columns
   $columns_content = explode ('[jcol/]', $content);

   // If 'model=' skipped - equal columns will result.
   if (!$model)
      {
      // 1,1,1,1,1
      $model = rtrim (str_repeat ("1,", count($columns_content)), ',');
      }

   $column_specs = array();
   $total_units  = 0;
   $model_arr = explode (',', $model);
   $chars = count ($model_arr);
   for ($i=0; $i<$chars; $i++)
      {
      $column_specs[] = $model_arr[$i];
      $total_units += $model_arr[$i];
      }

   $total_columns = count($column_specs);
   $pct_per_unit = 100/$total_units;

   $table_columns = "";
   $colcss_current = $colcss_any;   // Used to be different for first/last, now the same.
   for ($i=0; $i<$total_columns; $i++)
      {
      $column_width_pct = floor($column_specs[$i] * $pct_per_unit);
      $column_content   = $columns_content[$i];

      if ($stripbr == 'yes')
         {
         $column_content = JAY__trim_br ($column_content);
         }

      $column_content = JAY__strip_p_tags ($column_content);  // Strip <p> tags around content

      $table_columns .= "<td width=\"{$column_width_pct}%\" align=\"{$halign}\" valign=\"{$valign}\" style=\"{$topbordercss}{$bottombordercss}{$valign_css_rule}\"><div align=\"{$halign}\" {$colclass_txt} style=\"{$colcss_current};\">{$column_content}</div></td>";
      if ($i != ($total_columns-1))
         {
         // Insert "gap" column
         $table_columns .= $inner_gap_html;
         }
      }

$layout_table =<<<TTT
<div align="center" style="display:block;clear:both;margin:0;padding:0;">
   <table style="margin:0;table-layout:fixed;" width="100%" border="0" cellspacing="0" cellpadding="0">
     <tr valign="{$valign}">
       {$left_gap_html}
       {$table_columns}
       {$right_gap_html}
     </tr>
   </table>
</div>
TTT;

   return JAY__do_shortcode ($layout_table);
}
//===========================================================================

//===========================================================================
//
// Support for MemberWing-X membership plugin, http://www.memberwing.com
/*

[j-memberwing  conditions="*?"]
   .... only members who matches the 'condition' will see this
   [j-else/]
   .... only people who does not match the condition will see this
[/j-memberwing]

*/

function JAY__shortcode__jmemberwing ($atts, $content="")
{
   extract (shortcode_atts (
      array(
         'conditions'         => '?',         // Stuff in between {{{...}}} brackets. Ex: "gold" or "gold|silver"
         ),
         $atts));


   $content = JAY__fix_content ($content);   // Fix bug (</p>...content...<p>) introduced by wpautop + 'add_shortcode' + condition where content is surrounded by empty lines.

   $condition_is_true   = FALSE;
   $mwx_installed       = TRUE;

   if (function_exists ('MWX__UserCanAccessArticle'))
      {
       // first parameter: article/page ID. -1 => current article, second  parameter: user_id. -1 => currently logged on user. Third parameter:  premium marker string (stuff inside {{{...}}} brackets)
      $access_info = MWX__UserCanAccessArticle (-1, -1, $conditions, FALSE);
      if ($access_info)
         {
         if ($access_info['immediate_access'])
            {
            // current visitor can access article protected with {{{gold:5d|platinum}}} premium marker immediately
            $condition_is_true = TRUE;
            }
         else
            {
            // Note: this will only work for MemberWing-X TSI Edition. Other editions will always return '0'.
            // current visitor can access article protected with  {{{gold:5d|platinum}}} premium marker in ' . $access_info['in_seconds'] .  ' seconds'
            $condition_is_true = FALSE;
            }
         }
      else
         {
         // current visitor does not have access to article protected with {{{gold:5d|platinum}}} premium marker
         $condition_is_true = FALSE;
         }
      }
   else
      {
      $condition_is_true = FALSE;
      $mwx_installed     = FALSE;
      }

   $content_arr = explode ('[j-else/]', $content);
   if (!isset($content_arr[1]))
      $content_arr[1] = '';

   $final_content = '';

   // action = "allow"
   if ($condition_is_true)
      {
      $final_content = $content_arr[0];
      }
   else
      {
      $final_content = $content_arr[1];
      if (!$mwx_installed)
         {
         $final_content .= '<h3 align="center"><span style="color:red;">Warning:</span> <a href="http://www.memberwing.com/">MemberWing-X</a> is not installed</h3>';
         }
      }

   $final_content = JAY__strip_p_tags ($final_content);  // Strip <p> tags around content

   return JAY__do_shortcode ($final_content);
}
//===========================================================================

//===========================================================================
//
// Allows embedding pages/posts inside of other pages or posts
/*

[jpage id="123"]

*/

function JAY__shortcode__jpage ($atts, $content="")
{
   extract (shortcode_atts (
      array(
         'id' => '',
         ),
         $atts));

   $page_id = $id;

   if (!$page_id)
      return "";

   // You must pass in a variable to the get_page function. If you pass in a value (e.g. get_page ( 123 ); ), Wordpress will generate an error.
   /*
   Object's members:
   [ID]                    => (integer)
   [post_author]           => (integer)
   [post_date]             => (YYYY-MM-DD HH:MM:SS)
   [post_date_gmt]         => (YYYY-MM-DD HH:MM:SS)
   [post_content]          => (all post content is in here)
   [post_title]            => (Post Title Here)
   [post_excerpt]          => (Post Excerpt)
   [post_status]           => (? | publish)
   [comment_status]        => (? | closed)
   [ping_status]           => (? | closed)
   [post_password]         => (blank if not specified)
   [post_name]             => (slug-is-here)
   [to_ping]               => (?)
   [pinged]                => (?)
   [post_modified]         => (YYYY-MM-DD HH:MM:SS)
   [post_modified_gmt]     => (YYYY-MM-DD HH:MM:SS)
   [post_content_filtered] => (?)
   [post_parent]           => (integer)
   [guid]                  => (a unique identifier that is not necessarily the URL to the Page)
   [menu_order]            => (integer)
   [post_type]             => (? | page)
   [post_mime_type]        => ()?)
   [comment_count]         => (integer)
   [ancestors]             => (object|array)
   [filter]                => (? | raw)
   */
   $page_data = get_page ($page_id);

   // Get Content and do all Wordpress filters including shortcodes.
   $content = apply_filters ('the_content', $page_data->post_content);

   return $content;
}
//===========================================================================

//===========================================================================
//
// BETA! subject to change
// Allows embed RSS feeds inside of any post, page or sidebar widget.
/*

[jfeed url="" items="*10"]

*/

function JAY__shortcode__jfeed ($atts, $content="")
{
   extract (shortcode_atts (
      array(
         'url'          => 'http://www.jshortcodes.com/feed/',
         'items'        => '10',

         'warnings'     => '0',                                      // Show feed warnings/error messages
         'msgerror'     => '<p>Fetch feed error. Bad feed URL?</p>', // Will be shown only if "warnings" is set to "1"
         'msgempty'     => '<p>No feed items found</p>',             // Will be shown only if "warnings" is set to "1"

         'templatefeed' => '<ul class="jfeed">{FEED_ITEMS}</ul>',
         'templateitem' => '<li class="jfeed_li"><img src="{ITEM_IMAGE}" style="float:left;margin-right:6px;height:50px;border:1px solid gray;{SHOW_IMAGE}" /><a target="_blank" href="{ITEM_PERMALINK}">{ITEM_TITLE}</a><div>{ITEM_CONTENT}</div></li>',

         'maxchars'     => "200",                                    // Maximum number of characters to show for each feed item. -1 = show full content, 0 = only title will be shown.
         ),
         $atts));

   if (!$url)
      return $warnings?$msgerror:"";

   // Get a SimplePie feed object from the specified feed source.
   $rss = fetch_feed ($url);

   if (!is_wp_error ($rss))
      {
      // Figure out how many total items there are, but with the upper limit
      $maxitems = $rss->get_item_quantity ($items);

      if (!$maxitems)
         return $warnings?$msgempty:"";

      // Build an array of all the items, starting with element 0 (first element).
      $rss_items_arr = $rss->get_items(0, $maxitems);

      $feed_items_html = "";

      foreach ($rss_items_arr as $item)
         {
         $item_permalink   = $item->get_permalink();
         $item_date        = $item->get_date  ('j F Y | g:i a');
         $item_title       = $item->get_title ();
         $item_content     = $item->get_content ();

         // Detect presence of image inside of feed content. If image is not present - suppress it via 'display:none;' CSS tag.
         $item_image = FALSE;
         if (preg_match_all ('@\<img[^\>]+src=[\'\"]([^\'\"]+)[\'\"]@i', $item_content, $matches, PREG_SET_ORDER))
            {
            foreach ($matches as $match)
            if (strpos (@$match[1], 'http://feeds.feedburner.com') === FALSE)
               {
               $item_image = $match[1];
               break;
               }
            }
         if (!$item_image)
            $show_image = 'display:none;';
         else
            $show_image = '';


         $item_content     = strip_tags ($item_content);
         $item_content     = substr ($item_content, 0, $maxchars);
         $item_content     = preg_replace ('@[^a-zA-Z0-9]+[a-zA-Z0-9]*$@', " ...", $item_content);

         $temp_output      = $templateitem;
         $temp_output      = str_replace ('{ITEM_IMAGE}',      $item_image,      $temp_output);
         $temp_output      = str_replace ('{SHOW_IMAGE}',      $show_image,      $temp_output);
         $temp_output      = str_replace ('{ITEM_PERMALINK}',  $item_permalink,  $temp_output);
         $temp_output      = str_replace ('{ITEM_TITLE}',      $item_title,      $temp_output);
         $temp_output      = str_replace ('{ITEM_DATE}',       $item_date,       $temp_output);
         $temp_output      = str_replace ('{ITEM_CONTENT}',    $item_content,    $temp_output);

         $feed_items_html          .= $temp_output;
         }

      $output = str_replace ('{FEED_ITEMS}', $feed_items_html, $templatefeed);
      }
   else
      return $warnings?$msgerror:"";

   return $output;
}
//===========================================================================

//===========================================================================
//
// Allows embed RSS feeds inside of any post, page or sidebar widget.
/*

[jtabs
   size="xxxsmall|xxsmall|xsmall|small|*normal"
   theme="blitzer|cupertino|overcast|*smoothness|vader"
   width="*"
   ]
      Hello World::
      This is hello world. This
      is wonderful article
   [jtab/]
      Yes!::
      This is second tab
[/jtabs]

*/

function JAY__shortcode__jtabs ($atts, $content="")
{
   global  $g_theme_unavail_message;

   extract (shortcode_atts (
      array(
         'theme'        => 'smoothness',
         'size'         => 'normal',
         'width'        => '',
         ),
         $atts));

   $content = JAY__fix_content ($content);   // Fix bug (</p>...content...<p>) introduced by wpautop + 'add_shortcode' + condition where content is surrounded by empty lines.

   $jay_settings = JAY__get_settings();

   if (!$jay_settings['jquery_themes'][$theme])
      {
      $unavail_msg = str_replace ('{THEME}', $theme, $g_theme_unavail_message);
      if (!$jay_settings['jquery_themes']['smoothness'])
         return $unavail_msg;
      $theme = 'smoothness';
      }
   else
      {
      $unavail_msg = "";
      }

   $jtabs_styles_css = array();
   if ($width)
      $jtabs_styles_css[] = "width:{$width}px";

   $jtabs_styles = implode (';', $jtabs_styles_css);
   if ($jtabs_styles)
      $jtabs_styles = "style=\"{$jtabs_styles};\"";

$jtabs_template=<<<TTT
<div class="{$size} jayq-all jayq-{$theme}" {$jtabs_styles}>
   <div class="jtabs">
      <ul>
         {{{LI_ELEMENTS}}}
      </ul>
         {{{DIV_ELEMENTS}}}
   </div>
</div>
TTT;

   $content_arr = explode ('[jtab/]', $content);

   foreach ($content_arr as $idx=>$el)
      $content_arr[$idx] = JAY__strip_p_tags ($el);  // Strip <p> tags around content

   $li_elements = "";
   $div_elements = "";
   foreach ($content_arr as $idx=>$content_el)
      {
      $tab_data = explode ('::', $content_el, 2);
      if (count($tab_data) != 2)
         {
         $tab_data = explode (' ', $content_el, 2);
         }

      $li_elements  .= ('<li><a href="#jtabs-' . strval($idx+1) . '">' . JAY__trim_br($tab_data[0]) . '</a></li>');
      $div_elements .= ('<div id="jtabs-' . strval($idx+1) . '">' . $unavail_msg . JAY__trim_br($tab_data[1]) . '</div>');
      }

   $output = $jtabs_template;
   $output = str_replace ('{{{LI_ELEMENTS}}}',  $li_elements,  $output);
   $output = str_replace ('{{{DIV_ELEMENTS}}}', $div_elements, $output);

   return JAY__do_shortcode ($output);
}
//===========================================================================

//===========================================================================
//
// Allows embed RSS feeds inside of any post, page or sidebar widget.
/*

[jaccordion
   size="xxxsmall|xxsmall|xsmall|small|*normal"
   theme="blitzer|cupertino|overcast|*smoothness|vader"
   width="*"
   active="*"
   ]
      Hello World::
      This is hello world. This
      is wonderful article
   [jacc/]
      Yes!::
      This is second tab
[/jaccordion]

*/

function JAY__shortcode__jaccordion ($atts, $content="")
{
   global  $g_theme_unavail_message;

   extract (shortcode_atts (
      array(
         'theme'        => 'smoothness',
         'size'         => 'normal',
         'active'       => FALSE,            // 1-based active panel
         'width'        => '',
         ),
         $atts));

   $content = JAY__fix_content ($content);   // Fix bug (</p>...content...<p>) introduced by wpautop + 'add_shortcode' + condition where content is surrounded by empty lines.

   $jay_settings = JAY__get_settings();

   // Note: admin pages preloads all themes
   if (!$jay_settings['jquery_themes'][$theme] && !is_admin())
      {
      $unavail_msg = str_replace ('{THEME}', $theme, $g_theme_unavail_message);
      if (!$jay_settings['jquery_themes']['smoothness'])
         return $unavail_msg;
      $theme = 'smoothness';
      }
   else
      {
      $unavail_msg = "";
      }

   if ($active > 0)
      {
      $active--;
      $active_pane = "active_pane=\"{$active}\"";
      }
   else
      $active_pane = "";

   $jaccordion_styles_css = array();
   if ($width)
      $jaccordion_styles_css[] = "width:{$width}px";

   $jaccordion_styles = implode (';', $jaccordion_styles_css);
   if ($jaccordion_styles)
      $jaccordion_styles = "style=\"{$jaccordion_styles};\"";

$jtabs_template=<<<TTT
<div class="jayq-all {$size} jayq-{$theme}" {$jaccordion_styles} >
   <div {$active_pane} class="jaccordion">
       {{{DIV_ELEMENTS}}}
   </div>
</div>
TTT;

   $content_arr = explode ('[jacc/]', $content);

   $div_elements = "";
   foreach ($content_arr as $idx=>$content_el)
      {
      $content_el = JAY__strip_p_tags ($content_el);
      $tab_data = explode ('::', $content_el, 2);
      if (count($tab_data) != 2)
         {
         $tab_data = explode (' ', $content_el, 2);
         }

      $div_elements .= '<div><a href="#">' . JAY__trim_br($tab_data[0]) . '</a></div><div>' . $unavail_msg . JAY__trim_br($tab_data[1]) . '</div>';
      }

   $output = $jtabs_template;
   $output = str_replace ('{{{DIV_ELEMENTS}}}', $div_elements, $output);

   return JAY__do_shortcode ($output);
}
//===========================================================================

//===========================================================================
//
// Allows embed RSS feeds inside of any post, page or sidebar widget.
/*


[jgallery
   wh="600x400|50x50"
   image_params="fill:0,maxchars:calc"
   icon_params="pos:bottom,fill:1,all:0,icons:4"
   g_params=""
   maxslides="*"                                         // Show up to this number of slides. 0=show all (default)
   css="background-color:red;border:1px solid gray;"
   duration="4000"                                       // In ms. How long each slide to be shown. 0 = no slideshow.
   newpage="*0"                                          // "1" => open new browser windows when clicking on links in rich HTML panel
   ]
    http://SITE.COM/image1.png :: <h1>Great image 1</h1> :: image 1
    [jgal/]
    http://SITE.COM/image2.png :: <h1>Great image 2</h1>
    [jgal/]
    http://SITE.COM/image3.png
    [jgal/]
    wp_query::cat=25&post_limits=10
   /public_html/images/* :: http://SITE.com/my/images :: |.*|     // Anything after second :: will be interpreted as regex pattern for '|XXX|' filespec match.

[/jgallery]

*/

function JAY__shortcode__jgallery ($atts, $content="")
{
   static $id_counter=1;
   $id_counter++;          // Make ID of each gallery unique (in case of multiple galleries)

   extract (shortcode_atts (
      array(
         'wh'           => '600x400|60x40',  // "600x400|50x50" (both panels), "600x400" (only big images), "|50x50" (only icons/filmstrip)
         'image_params' => "fill:0",
         'icon_params'  => "pos:bottom,fill:1,all:0",
         'g_params'     => "",
         'maxslides'    => "0",              // Show up to this number of slides. 0=show all (default)
         'css'          => '',
         'duration'     => FALSE,            // Duration in ms for each slide to be shown. "0" - no slide show
         'newpage'      => '0',              // "1" => open new browser window when clicking on links in rich HTML panel content.
         ),
         $atts));


   $jay_settings = JAY__get_settings();
   if (!@$jay_settings['jgallery_enabled'])
      {
      $error_msg = '<div align="center" style="border:1px solid red;margin:3px;padding:3px;font-size:11px;line-height:13px;background-color:#ffd;">Warning: [jgallery] shortcode must be enabled via J-Shortcodes settings panel:<br />Wordpress Admin&nbsp;-&gt;&nbsp;J-Shortcodes&nbsp;-&gt;&nbsp;General Settings&nbsp;-&gt;&nbsp;[jgallery] Settings, before it could be used.</div>';
      return $error_msg;
      }

   $content = JAY__fix_content ($content);   // Fix bug (</p>...content...<p>) introduced by wpautop + 'add_shortcode' + condition where content is surrounded by empty lines.

//   $jay_settings = JAY__get_settings();

$js_default_params = array (

// NOTE: These are all possible settings for GalleryView. Uncommenting them would set them as default value, that could be overriden via command line.
//
//   // Global/overall settings
//    'jg_wrapper_css'        =>    "'border: 1px solid gray; background-color:#333;'". Analog: [jgallery css="..."]
//    'jg_frame_css'          =>    "'border: none;'",                                . Analog: [jgallery framecss="..."]
//
//    'transition_speed'      =>    800,                    // INT - duration of panel/frame transition (in milliseconds). Time image is shown
//    'transition_interval'   =>    5000,                   // INT - delay between panel/frame transitions (in milliseconds). "0"-no autoplay.
//
    'pointer_size'          =>    6,                      // INT - Height of frame pointer (in pixels)
//    'animate_pointer'       =>    "true",                 //BOOLEAN - flag to animate pointer or move it instantly to target frame
//
//    // REMOVED: - no longer necessary as navigation images are defined in CSS
//    // 'nav_theme'             =>    '"light"',              // STRING - name of navigation theme to use (folder must exist within 'themes' directory)
//    // 'theme_format'          =>    '"png"',                // STRING - extension of navigation images found in theme folder
//    'easing'                =>    '"swing"',              // STRING - easing method to use for animations ('swing', 'linear', 'easeInOutBack'. more available with jQuery UI or Easing plugin)
//    'pause_on_hover'        =>    "true",                 // BOOLEAN - flag to pause slideshow when user hovers over the gallery
//
//    // NOTE: These doesn't seems to have any effect. Replaced with corresponding jg_wrapper_* values to be applied to CSS of wrapper element directly.
//    // background_color: 'transparent',    // transparent or CSS color, such as "#123ABC"
//    //'border' => '"4px solid red;"',                     // CSS value, such as "none" or "1px solid black".
//    'nav_theme'             =>    '"dark"',
//    'easing'                =>    '"easeInOutQuad"',
    'pause_on_hover'        =>    "true",
//
//    // Main panel
//    'show_panels'           =>    "true",                 // BOOLEAN - flag to show or hide panel portion of gallery
//    'show_panel_nav'        =>    "true",                 //BOOLEAN - flag to show or hide panel navigation buttons
//    'panel_width'           =>    600,                    // INT - width of gallery panel (in pixels)
//    'panel_height'          =>    400,                    // INT - height of gallery panel (in pixels)
//    'panel_animation'       =>   '"crossfade"',           //STRING - animation method for panel transitions (fade,crossfade,slide,zoom,none)
//    'panel_scale'           =>    '"nocrop"',             //STRING - cropping option for panel images (crop = scale image and fit to aspect ratio determined by panel_width and panel_height, nocrop = scale image and preserve original aspect ratio)
//    'slide_method'          =>    '"strip"',              // 'strip', 'pointer'.
//
//    // Filmstrip panel
//    'show_filmstrip'        =>    "true",                 // BOOLEAN - flag to show or hide filmstrip portion of gallery
//    'show_filmstrip_nav'    =>    "true",                 //BOOLEAN - flag indicating whether to display navigation buttons
//
//    'frame_width'           =>    60,                     // INT - width of filmstrip frames (in pixels)
//    'frame_height'          =>    40,                     // INT - width of filmstrip frames (in pixels)
    'frame_opacity'         =>    0.5,                    // FLOAT - transparency of non-active frames (1.0 = opaque, 0.0 = transparent)
//    'frame_scale'           =>    '"crop"',               // STRING - cropping option for filmstrip images (same as above)
    'frame_gap'             =>    3,                      // (*5) INT - spacing between frames within filmstrip (in pixels)
//    'start_frame'           =>    1,                      // INT - index of panel/frame to show first when gallery loads
    'filmstrip_size'        =>    4,
//  'filmstrip_style'       =>     '"show all"',             //STRING - type of filmstrip to use ('scroll', 'show all')
//    'filmstrip_position'    =>    '"bottom"',             // STRING - position of filmstrip within gallery (bottom, top, left, right)
//    'show_captions'         =>    "true",                 // BOOLEAN - flag to show or hide frame captions
//    'caption_text_color'    =>    '"#222"',               //  CSS value: "#222", "#ABC123", "black"
//
//    // Overlay (text on top of big image)
//    'overlay_opacity'       =>    0.7,                    // FLOAT - transparency for panel overlay (1.0 = opaque, 0.0 = transparent)
//    'overlay_position'      =>    '"bottom"',             // STRING - position of panel overlay (bottom, top, left, right)
    'show_overlays'         =>    'true',                 //true / false

   );

   //---------------------------------------
   // Process input params...
   if ($newpage == '1' || $newpage == 'yes')
      $target_blank = 'target="_blank"';
   else
      $target_blank = '';

   // Set main (wrapper) and frame CSS
   if ($css)
      {
      $js_default_params['jg_wrapper_css'] = "'{$css}'";
      }

   // Set duration of slide
   if ($duration !== FALSE)
      {
      // Time image is shown = transition_interval - transition_speed.
      $js_default_params['transition_interval'] = $duration;
      }
   //---------------------------------------

   //---------------------------------------
   // Assemble javascript WxH params for main panel and icons.
   // Example: "800x600|80x60"  or "800x600"  or "|80x60"
   $allp = explode ('|', $wh);

   if ($allp[0])
      {
      // First dimensions are set
      if ($allp[1])
         {
         // Both panels are present
         $panel1 = explode ('x', $allp[0]);
         $panel2 = explode ('x', $allp[1]);
         if ($panel1[0] > $panel2[0])
            {
            $big_panel   = $panel1;
            $small_panel = $panel2;
            }
         else
            {
            $big_panel   = $panel2;
            $small_panel = $panel1;
            }
         }
      else
         {
         // First set, second - not. Only main image panel is present
         $big_panel   = explode ('x', $allp[0]);
         $small_panel = FALSE;
         }
      }
   else
      {
      // Main image panel is absent. Only filmstrip is present
      $big_panel   = FALSE;
      $small_panel = explode ('x', $allp[1]);
      }

   //---------------------------------------
   // Convert '$image_params' and 'icon_params' into assoc arrays.
   // Example of input: "pos=top,fill=1,all=1"
   // Processing big ...
   $image_params_arr   = array();  // Assoc array of params related to big images.
   foreach (explode (',', $image_params) as $param)
      {
      $kv = explode (':', $param);
      $image_params_arr[$kv[0]] = $kv[1];
      }

   // Processing small ...
   $icon_params_arr   = array();  // Assoc array of params related to small images - icons.
   foreach (explode (',', $icon_params) as $param)
      {
      $kv = explode (':', $param);
      $icon_params_arr[$kv[0]] = $kv[1];
      }

   // Processing global gallery params
   $gallery_params_arr = array(); // Assoc array of params related to gallery script itself.
   foreach (explode (',', $g_params) as $param)
      {
      $kv = explode (':', $param);
      if (@$kv[1])
         {
         if (is_numeric($kv[1]) || $kv[1]=='true' || $kv[1] == 'false')
            $js_default_params[$kv[0]] = $kv[1];
         else
            $js_default_params[$kv[0]] = "'{$kv[1]}'";
         }
      }
   //---------------------------------------

   // Transfer input params into js params

   // Set dimensions
   if ($big_panel)
      {
      $js_default_params['show_panels']  = "true";
      $js_default_params['panel_width']  = $big_panel[0];
      $js_default_params['panel_height'] = $big_panel[1];
      }
   else
      {
      // Big panel is absent
      $js_default_params['show_panels']  = "false";
      }

   if ($small_panel)
      {
      $js_default_params['show_filmstrip']  = "true";
      $js_default_params['frame_width']  = $small_panel[0];
      $js_default_params['frame_height'] = $small_panel[1];

      // In case filmstrip specificed with position: pos=top
      if (@$icon_params_arr['pos'])
         $js_default_params['filmstrip_position'] = "'{$icon_params_arr['pos']}'";
      else
         $js_default_params['filmstrip_position'] = "'bottom'";   // If location of filmstrip is not specified - this will be default.

      if (@$icon_params_arr['icons'])
         $js_default_params['filmstrip_size'] = $icon_params_arr['icons'];
      }
   else
      {
      $js_default_params['show_filmstrip']  = "false";
      }

   // -------------------------------------------
   // Set defaults and other input params
   if (@$icon_params_arr['all'])
      {
      $js_default_params['filmstrip_style'] = '"show all"';
      }

   // For big images - default "no fill" unless explicitly specified.
   if (@$image_params_arr['fill'])
      $js_default_params['panel_scale'] = '"crop"';
   else
      $js_default_params['panel_scale'] = '"nocrop"';

   if (!@$image_params_arr['maxchars'])
      $image_params_arr['maxchars'] = 'calc';

   // For small images - default is "fill" unless explicitly specified to "no fill"
   // !is_numeric(@$icon_params_arr['fill'])  - means not specified at all
   if (!is_numeric(@$icon_params_arr['fill']) || @$icon_params_arr['fill'])
      $js_default_params['frame_scale'] = '"crop"';      // Full frame is filled with pixels.
   else
      $js_default_params['frame_scale'] = '"nocrop"';    // possible white lines on a side
   // -------------------------------------------
   //---------------------------------------

   //---------------------------------------
   // Now process main content/images

   if (@$image_params_arr['maxchars'] == 'calc')
      $maxchars = ($js_default_params['panel_width'] * $js_default_params['panel_height']) / 300;
   else
      $maxchars = (int) $image_params_arr['maxchars'];

   $content_arr = explode ('[jgal/]', $content);

   $li_elements = "";
   $slides_created = 0;
   foreach ($content_arr as $idx=>$content_el)
      {
      $content_el = JAY__strip_p_tags ($content_el);
      $content_el = JAY__trim_br ($content_el);
      $content_el = str_replace ('&#038;', '&', $content_el);  // Restore '&' chars.

      $img_data = explode ('::', $content_el);
      $img_data_arr = array();
      foreach ($img_data as $el)
         {
         // Fix content
         $img_data_arr[] = trim (strip_tags($el));
         }
      $img_data_orig = $img_data;   // Unfiltered
      $img_data      = $img_data_arr;

      $image_alt_tag = ""; // Must be full tag (or empty): 'alt="blah"';
      $image_url        =  $img_data[0];

      //------------------------------------
      // Gallery element: single image
      if (strpos($image_url, "http")===0)
         {
         // Direct image URL specified
         $extra_content_type = "overlay"; // Extra stuff after image URL is dark overlay text on top of picture

         $image_extra_content    =  @$img_data_orig[1];  // Pull unfiltered values, possibly with HTML
         $image_title_tag        =  @$img_data_orig[2];
         if ($image_title_tag)
            $js_default_params['show_captions'] = "true";

         $li_element =
            JAY__jgallery_Assemble_LI_Element (
               $image_url,
               $image_extra_content,
               $image_title_tag,
               ""
               );

         $slides_created ++;
         }
      //------------------------------------

      //------------------------------------
      // Gallery element: blog posts
      else if ($image_url == 'wp_query')
         {
         // Instead of images we will display post excerpts from selected requested posts.
         $extra_content_type = "content"; // Extra stuff after image URL is rich HTML to be inserted is slide instead of picture.

         $li_element_arr = array();

         $wp_query_params = @$img_data[1];
         if (!$wp_query_params)
            $wp_query_params = 'posts_per_page=10&paged=1&offset=0';

         // WP Query params to select posts specified. Loop through it.
         $custom_query = new WP_Query ($wp_query_params);

         // The Loop
         while ($custom_query->have_posts())
            {
            $custom_query->the_post();
            // Post ID = get_the_ID();

            //-----------------------------------
            // Do our best to extract image from post.
            if (function_exists('has_post_thumbnail') && has_post_thumbnail ())
               {
               // This will detect featured image.
               $image_url = wp_get_attachment_image_src (get_post_thumbnail_id(), 'full');
               $image_url = @$image_url[0];
               }
            else if (preg_match ('@<img\s[^>]*src=[\'\"]([^\'\"]+)@', get_the_content(), $matches))
               {
               // Otherwise let scan post content for the first <img> tag
               $image_url = $matches[1];
               }
            else
               {
               // Post content does not contain images. Search for image in attachments...
               $attachments =
                  get_children (
                     array (
                        'post_parent'     => get_the_ID(),
                        'post_status'     => 'inherit',
                        'post_type'       => 'attachment',
                        'post_mime_type'  => 'image',
                        'order'           => 'ASC',
                        'orderby'         => 'menu_order ID',
                        )
                     );

               if (!empty ($attachments))
                  {
                  foreach ($attachments as $att_id => $attachment)
                     {
                     $image_url = wp_get_attachment_image_src ($att_id, 'full');
                     $image_url = @$image_url[0];
                     break;
                     }
                  }
               else
                  $image_url = FALSE;
               }
            //-----------------------------------

            if (!$image_url)
               {
               // This post has no image. Set it to some default for now.
               $show_image_css = 'display:none;';  // Don't show any image in main panel, but icon needs to show something

               global $g_JAY__plugin_directory_url;
               $image_url = $g_JAY__plugin_directory_url . '/images/default_frame.png';
               }
            else
               {
               $show_image_css = "";
               }

            $image_alt_tag       = "";
            $post_title          = get_the_title ();
            $post_permalink      = get_permalink();
            $image_title_tag     = 'title="' . $post_title . '"';

            if ($extra_content_type == "content")
               {
               // Slide is rich HTML - big chunk of post, including detected image
               $post_content     = get_the_content ();
               $post_content     = apply_filters ('the_content', $post_content);
               $post_content     = strip_tags ($post_content);
               if ($maxchars)
                  {
                  // Cut post content to set limit of number of chars
                  $post_content = substr ($post_content, 0, $maxchars);
                  $post_content = preg_replace ('@[^a-z0-9\-\_][a-z0-9\-\_]*$@i', " ...", $post_content);   // Find last word break.
                  $post_content = $post_content . JAY__do_shortcode ("<div class=\"jg_read_more\" style=\"float:right;\">[jbutton color=\"darkgray\" size=\"small\" link=\"{$post_permalink}\"]<b>Read more</b>[/jbutton]</div>");
                  }

               if ($js_default_params['panel_height'] < $js_default_params['panel_width'])
                  $image_sizelimit_tag  = 'height="' . $js_default_params['panel_height'] / 3 . '"';
               else
                  $image_sizelimit_tag  = 'width="' . $js_default_params['panel_width'] / 3 . '"';

               $image_extra_content =<<<TTT
                  <div class="jg-post-wrapper">
                     <a {$target_blank} href="{$post_permalink}" class="jg-post-image-link"><img src="{$image_url}" class="jg-post-image" {$image_sizelimit_tag} style="{$show_image_css}" /></a>
                     <div class="jg-post-title"><a class="jg-post-title-link" {$target_blank} href="{$post_permalink}">{$post_title}</a></div>
                     <div class="jg-post-content" >{$post_content}</div>
                  </div>
TTT;
               }
            else
               {
               // $extra_content_type == "overlay"
               // Slide is only image from post + linkable excerpt from post as overlay over image.
               $image_extra_content =<<<TTT
                  <a {$target_blank} href="{$post_permalink}">{$post_title}</a>
TTT;
               }

            $li_element_arr[] =<<<TTT
               <li>
                  <img src="{$image_url}" {$image_alt_tag} {$image_title_tag} />
                  <div class="gv-panel-{$extra_content_type}">
                     {$image_extra_content}
                  </div>
               </li>
TTT;
            $slides_created ++;
            if ($maxslides && $slides_created >= $maxslides)
               break;   // Break
            }

         if (function_exists('wp_reset_postdata')) // Since WP 3.0.x
            {
            wp_reset_postdata ();
            }

         $li_element = implode ($li_element_arr);
         }
      //------------------------------------

      //------------------------------------
      // Gallery element - list of image files at physical location:
      //   /public_html/images/* :: http://SITE.com/my/images :: |.*|
      else if ($image_url[0] == '/' && $image_url[strlen($image_url) - 1] == '*')
         {
         $web_url = @$img_data[1];
         $pattern = @$img_data[2];

         if (!$pattern)
            $pattern = '@.*\\.(jpe?g|png|bmp|gif)$@i';

         if ($maxslides)
            $limit = $maxslides - $slides_created;
         else
            $limit = 0;

         $image_urls = JAY__Get_Image_URLs ($image_url, $web_url, $pattern, $limit, FALSE);

////////////////////////////////!!!
///!!!$return_data =<<<TTT
///!!!image_url = '$image_url' <br />
///!!!web_url   = '$web_url'   <br />
///!!!pattern = '$pattern'     <br />
///!!!limit  = '$limit'        <br />
///!!!image_urls =             <br />
///!!!TTT;
///!!!$return_data .= serialize ($image_urls);
///!!!return $return_data;
////////////////////////////////!!!

         $li_elements_arr = array();
         foreach ($image_urls as $image_url)
            {
            $li_elements_arr[] =
               JAY__jgallery_Assemble_LI_Element (
                  $image_url,                         // Image URL
                  "",                                 // Image overlay or extra content
                  "",                                 // Image title="" text that will be used as caption for icons.
                  ""                                  // Image alt="" text.
                  );

            $slides_created ++;
            }

         $li_element = implode ($li_elements_arr);
         }
      //------------------------------------

      //------------------------------------
      else
         {
         continue;
         }
      //------------------------------------

      $li_elements .= $li_element;

      if ($maxslides && $slides_created >= $maxslides)
         break;   // Break
      }
   //---------------------------------------

   //---------------------------------------
   // Assemble $js_params
   $js_params = "";
   foreach ($js_default_params as $k=>$v)
      {
      $js_params .= "\n'{$k}' : $v,";
      }
   $js_params = rtrim ($js_params, ',');

   // Assemble $js_template
   $js_template =<<<TTT
      <script type="text/javascript">
         var jgallery_{$id_counter} = {
            {$js_params}
            };
     </script>
TTT;
   //---------------------------------------

   //---------------------------------------
   // Assemble final gallery HTML
   $j_gallery_html =<<<TTT
      <div class="jgallery" style="display:none;">
         {$js_template}
         <ul id="jgallery_{$id_counter}">
            {$li_elements}
         </ul>
      </div>
      <a class="js-ga" style="font-size:7px;" target="_blank" href="http://www.jshortcodes.com">wordpress gallery and slideshow plugin</a>
TTT;
   //---------------------------------------

   return JAY__do_shortcode ($j_gallery_html);
}
//===========================================================================

//===========================================================================
function JAY__jgallery_Assemble_LI_Element ($image_url, $image_overlay_or_extra_content, $image_title_caption_text="", $image_alt_text="")
{
   // Direct image URL specified
   $extra_content_type = "overlay"; // Extra stuff after image URL is dark overlay text on top of picture

   if ($image_title_caption_text)
      {
      $image_title_caption_tag = "title=\"{$image_title_caption_text}\"";
//    $js_default_params['show_captions'] = "true";
      }
   else
      $image_title_caption_tag = "";

   if ($image_alt_text)
      $image_alt_tag = "alt=\"{$image_alt_text}\"";
   else
      $image_alt_tag = "";

   if ($image_overlay_or_extra_content)
      {
      $li_element =<<<TTT
         <li>
            <img src="{$image_url}" {$image_alt_tag} {$image_title_caption_tag} />
            <div class="gv-panel-{$extra_content_type}">
               {$image_overlay_or_extra_content}
            </div>
         </li>
TTT;
      }
   else
      {
      $li_element =<<<TTT
         <li>
            <img src="{$image_url}" {$image_alt_tag} {$image_title_caption_tag} />
         </li>
TTT;
      }

   return $li_element;
}
//===========================================================================

?>