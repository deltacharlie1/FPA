<?php

/*
                                ==============
                                 J Shortcodes
                                ==============

    Collection of userful shortcodes to enrich any Wordpress Theme, Blog and Website

                       +------------------------------+
                       |  http://www.jshortcodes.com  |
                       +------------------------------+
*/

//---------------------------------------------------------------------------
// Globals
global $g_JAY__plugin_directory_url;   // Non-trail-slashed WEB URL of plugin directory.
$g_JAY__plugin_directory_url = rtrim (WP_PLUGIN_URL . '/' . str_replace (basename(__FILE__), "", plugin_basename(__FILE__)), '/');
//---------------------------------------------------------------------------

global $g_JAY__config_defaults;
$g_JAY__config_defaults = array (

// ------- Globals
   'j-shortcodes-version'  => J_SHORTCODES_VERSION,   // If get_settings() version is less than J_SHORTCODES_VERSION, then settings will be "reactivated".

// ------- General Settings
   'disable-wpautop'       => '',   // Auto-<p>...</p> tags insertion facility
   'custom_css'            => ".gallery img {border:none;}\n"                                .
                              ".gallery .nav-prev, .gallery .nav-next { width:auto;}\n"      .
                              "ul.filmstrip li { list-style: none; }"                        .
                              "",
   'webmaster_subscribed'  => '',   // '1' - webmaster of site subscribed to js mailing list.

// ------- Jquery Themes
   'jquery_themes'         => array (  // Which Jquery themes are enabled for frontend
                                 'blitzer'      => '0',
                                 'cupertino'    => '0',
                                 'overcast'     => '0',
                                 'smoothness'   => '1',  // Smoothness theme is default.
                                 'vader'        => '0',
                                 ),

// ------- JGallery
   'jgallery_enabled'      => '1',   // '1' - [jgallery] shortcode enabled
   );


//===========================================================================
// Recursively strip slashes from all elements of multi-nested array
function JAY__stripslashes (&$val)
{
   if (is_string($val))
      return (stripslashes($val));
   if (!is_array($val))
      return $val;

   foreach ($val as $k=>$v)
      {
      $val[$k] = JAY__stripslashes ($v);
      }

   return $val;
}
//===========================================================================

//===========================================================================
// Takes care of recursive updating
function JAY__update_individual_jay_setting (&$jay_current_setting, $jay_new_setting)
{
   if (is_string($jay_new_setting))
      $jay_current_setting = JAY__stripslashes ($jay_new_setting);
   else if (is_array($jay_new_setting))  // Note: new setting may not exist yet in current setting: curr[t5] - not set yet, while new[t5] set.
      {
      // Need to do recursive
      foreach ($jay_new_setting as $k=>$v)
         {
         if (!isset($jay_current_setting[$k]))
            $jay_current_setting[$k] = "";   // If not set yet - force set it to something.
         JAY__update_individual_jay_setting ($jay_current_setting[$k], $v);
         }
      }
   else
      $jay_current_setting = $jay_new_setting;
}
//===========================================================================

//===========================================================================
function JAY__get_settings ()
{
   $jay_settings = get_option ('J-Shortcodes');


   //------------------------------------------------------------------------
   // Load forced-default settings
   // ...
   //------------------------------------------------------------------------

   return ($jay_settings);
}
//===========================================================================

//===========================================================================
function JAY__update_settings ($jay_use_these_settings="")
{
   if ($jay_use_these_settings)
      {
      update_option ('J-Shortcodes', $jay_use_these_settings);
      return;
      }

   global   $g_JAY__config_defaults;

   // Load current settings and overwrite them with whatever values are present on submitted form
   $jay_settings = JAY__get_settings();

   foreach ($g_JAY__config_defaults as $k=>$v)
      {
      if (isset($_POST[$k]))
         {
         if (!isset($jay_settings[$k]))
            $jay_settings[$k] = ""; // Force set to something.
         JAY__update_individual_jay_setting ($jay_settings[$k], $_POST[$k]);
         }
      // If not in POST - existing will be used.
      }


   //---------------------------------------
   // Validation
   // ...
   //---------------------------------------

   update_option ('J-Shortcodes', $jay_settings);
}
//===========================================================================

//===========================================================================
//
// Reset settings only for one screen

function JAY__reset_partial_settings ()
{
   global   $g_JAY__config_defaults;

   // Load current settings and overwrite ones that are present on submitted form with defaults
   $jay_settings = JAY__get_settings();

   foreach ($_POST as $k=>$v)
      {
      if (isset($g_JAY__config_defaults[$k]))
         {
         if (!isset($jay_settings[$k]))
            $jay_settings[$k] = ""; // Force set to something.
         JAY__update_individual_jay_setting ($jay_settings[$k], $g_JAY__config_defaults[$k]);
         }
      }

   update_option ('J-Shortcodes', $jay_settings);
}
//===========================================================================

//===========================================================================
function JAY__reset_all_settings ()
{
   global   $g_JAY__config_defaults;

   update_option ('J-Shortcodes', $g_JAY__config_defaults);
}
//===========================================================================

//===========================================================================
function JAY__render_j_shortcodes_version ()
{
?>
   <div align="center" style="border:2px solid gray;font-size:130%;margin-top:10px;padding:5px;">
      <div style="margin-bottom:5px;">J-Shortcodes version: <span style="color:red;font-weight:bold;"><?php echo J_SHORTCODES_VERSION; ?></span></div>
      <span style="font-size:75%;font-weight:bold;background-color:#DDD;">&nbsp;&nbsp;<?php echo 'Your Wordpress version: ' . get_bloginfo('version'); ?>&nbsp;&nbsp;</span>
   </div>
<?php
}
//===========================================================================

//===========================================================================
function JAY__render_admin_page_html ($admin_page_name)
{
   echo '<div style="margin-top:35px;padding-right:20px;">';

   JAY__render_j_shortcodes_version ();

   switch ($admin_page_name)
      {
      case 'general'    :           JAY__render_general_settings_page_html ();         break;
      default:                                                                         break;
      }

   echo '</div>';
}
//===========================================================================

//===========================================================================
function JAY__render_general_settings_page_html ()
{
   global $g_JAY__plugin_directory_url;
   $jay_settings = JAY__get_settings();

   $admin_email = get_settings('admin_email');
   if (!$admin_email)
      $admin_email = get_option('admin_email');

   $signup_form = JAY__get_signup_form ($admin_email);
   if (@$jay_settings['webmaster_subscribed'])
      $active_pane = "";   // First setting active
   else
      $active_pane = 'active="1"';   // Signup form active

   $table_header_row =<<<TTT
      <tr>
         <td style="background-color:#eeffee" width="20%"><div align="center" style="padding:5px 3px;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 16px;">Setting name</div></td>
         <td style="background-color:#eeffee" width="50%"><div align="center" style="padding:5px 3px;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 16px;">Setting value</div></td>
         <td style="background-color:#eeffee" width="30%"><div align="center" style="padding:5px 3px;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 16px;">Notes</div></td>
      </tr>
TTT;

   $phys_path    = preg_replace ('@(/[^/]+){3}/?$@', '', dirname(__FILE__));
   $phys_path    = rtrim ($phys_path, '/') . '/';
   $web_url_path = preg_replace ('@(/[^/]+){3}/?$@', '', $g_JAY__plugin_directory_url);
   $web_url_path = rtrim ($web_url_path, '/') . '/';

   //---------------------------------------
   // Start output buffering
   ob_start();
   //---------------------------------------

?>
<div align="center" style="font-family: Georgia, 'Times New Roman', Times, serif;font-size:18px;margin:30px 0 10px;background-color:#e9f3ff;padding:14px;border:2px solid gray;">
   <b style="color:#087bf9;">J</b>-Shortcodes<br />
   <div style="color:#A00;font-size:130%;margin-top:10px;">General Settings</div>
</div>

[jaccordion theme="cupertino" size="normal" <?php echo $active_pane; ?>]

Tutorials, Tips and Notifications::
   <div align="center">
      <?php echo $signup_form; ?>
   </div>

[/jaccordion]

<form method="post" action="<?php echo $_SERVER['REQUEST_URI']; ?>">
[jaccordion theme="cupertino" size="normal"]

[<i></i><span style="color:red;">jtabs</span>] and [<i></i><span style="color:red;">jaccordion</span>] settings ::
   <table style="table-layout:fixed;background-color:gray;border-collapse: separate;" border="2" cellspacing="1" cellpadding="0" width="100%">
      <tr>
         <td style="background-color:#eeffee" colspan="5" align="center" valign="middle">
            <div style="padding:5px 3px;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 16px;" align="center">
               Enable themes for [<i></i>jtabs] and [<i></i>jaccordion] shortcodes
               <div align="left" style="font-size:11px;">Notes:
                  <br />&bull; Each theme requires separate stylesheet to be preloaded (about 40KB CSS file). Disable themes that you are not using to speed up page load times.
                  <br />&bull; These settings are only relevant for [<i></i>jtabs] and [<i></i>jaccordion] shortcodes.
                  <br />&bull; If you are not using [<i></i>jtabs] and [<i></i>jaccordion] shortcodes, you may disable all themes and save on page load times.
               </div>
            </div>
         </td>
      </tr>
      <tr>
         <?php foreach ($jay_settings['jquery_themes'] as $theme_name => $val) : ?>
         <?php
               { $input_extra_style = ''; $label = "Enabled? &nbsp;&nbsp;&nbsp;"; }
         ?>
            <td style="background-color:white;" align="center" valign="middle">
               <div align="center">theme="<b><?php echo $theme_name; ?></b>"<br />
                  <img src="<?php echo $g_JAY__plugin_directory_url . '/images/admin/' . $theme_name . '.png'; ?>" />
                  <div style="background-color:#f0f0f0;padding:3px;margin:3px;border:1px solid #6c966a;">
                     <?php echo $label; ?><input type="hidden" name="jquery_themes[<?php echo $theme_name; ?>]" value="0" /><input type="checkbox" style="float:none;<?php echo $input_extra_style; ?>" value="1" name="jquery_themes[<?php echo $theme_name; ?>]" <?php if ($val) echo ' checked="checked"'; ?> <?php echo $is_disabled; ?> />
                  <div>
               </div>
            </td>
         <?php endforeach; ?>

     </tr>
   </table>

[jacc/]

[<i></i><span style="color:red;">jgallery</span>] Settings ::
   <table style="table-layout:fixed;background-color:gray;border-collapse: separate;" border="2" cellspacing="1" cellpadding="0" width="100%">
      <?php echo $table_header_row; ?>
      <tr>
         <td style="background-color:white;" ><div align="left" style="padding-left:5px;">[<i></i>jgallery] shortcode enabled?</div></td>
         <td style="background-color:#CCC;"  ><div align="center"><input type="hidden" name="jgallery_enabled" value="0" /><input type="checkbox" style="float:none;" value="1" name="jgallery_enabled" <?php if ($jay_settings['jgallery_enabled']) echo ' checked="checked" '; ?> /></div></td>
         <td style="background-color:white;" >
            <div align="left" style="padding:5px;font-size:85%;line-height:110%;">
               Allows to disable [<i></i>jgallery] functionality. <br />If you are not using [<i></i>jgallery] shortcode you may disable it and save page load times. No jgallery-specific CSS and javascripts will be loaded.
            </div>
         </td>
      </tr>
      <tr>
         <td style="background-color:white;" ><div align="left" style="padding-left:5px;">Physical directory path:</div></td>
         <td style="background-color:#CCC;"  ><div align="center"><input type="text" value="<?php echo $phys_path; ?>" size="70" readonly="readonly" /></div></td>
         <td style="background-color:white;" >
            <div align="left" style="padding:5px;font-size:85%;line-height:110%;">
            </div>
         </td>
      </tr>
      <tr>
         <td style="background-color:white;" ><div align="left" style="padding-left:5px;">Web URL location:</div></td>
         <td style="background-color:#CCC;"  ><div align="center"><input type="text" value="<?php echo $web_url_path; ?>" size="70" readonly="readonly" /></div></td>
         <td style="background-color:white;" >
            <div align="left" style="padding:5px;font-size:85%;line-height:110%;">
            </div>
         </td>
      </tr>
   </table>

[jacc/]

Wpautop filter::
   <table style="table-layout:fixed;background-color:gray;border-collapse: separate;" border="2" cellspacing="1" cellpadding="0" width="100%">
      <?php echo $table_header_row; ?>
      <tr>
         <td style="background-color:white;" ><div align="left" style="padding-left:5px;">Disable Wordpress wpautop filter?</div></td>
         <td style="background-color:#CCC;"  ><div align="center"><input type="hidden" name="disable-wpautop" value="0" /><input type="checkbox" style="float:none;" value="1" name="disable-wpautop" <?php if ($jay_settings['disable-wpautop']) echo ' checked="checked" '; ?> /></div></td>
         <td style="background-color:white;" ><div align="left" style="padding:5px;font-size:85%;line-height:110%;">Disables Wordpress wpautop filter. Wordpress uses wpautop filter to change double line-breaks in the text into HTML paragraphs (<tt>&lt;p&gt;...&lt;/p&gt;</tt>).<br />Some people find it annoying and choose to disable it to get more self-control over text layout.</div></td>
      </tr>
   </table>

[jacc/]

Custom CSS ::
   <table style="table-layout:fixed;background-color:gray;border-collapse: separate;" border="2" cellspacing="1" cellpadding="0" width="100%">
      <?php echo $table_header_row; ?>
      <tr>
         <td style="background-color:white;"><div align="left" style="padding-left:5px;">Custom CSS:</div></td>
         <td style="background-color:#CCC;" ><div align="center"><textarea style="font-size:10px;width:95%;" name="custom_css" rows=10><?php echo $jay_settings['custom_css']; ?></textarea></div></td>
         <td style="background-color:white;"><div align="left" style="padding:5px;font-size:85%;line-height:110%;">Custom CSS code to add extra visual customizations to elements of your website.</div></td>
      </tr>
   </table>

[/jaccordion]

   <br />
   <table style="background-color:gray;border-collapse: separate;" border="2" cellspacing="1" cellpadding="0" width="100%">
      <tr>
         <td colspan="3" style="background-color:#ffffee;"><div align="center" style="padding:10px 0;">
            <input type="submit" style="border:3px solid green;background-color:#D8FFD8;" name="button_update_jay_settings" value="Save Settings" />&nbsp;&nbsp;&nbsp;&nbsp;
            <input type="submit" style="border:1px solid red;"                            name="button_reset_partial_jay_settings" value="Reset settings on this page to defaults" onClick="return confirm('Are you sure you want to reset settings on this page to defaults?');"/>&nbsp;&nbsp;&nbsp;&nbsp;
            <input type="submit" style="border:3px solid red;background-color:#FFA;"      name="button_reset_jay_settings" value="Reset ALL settings to all defaults" onClick="return confirm('Are you sure you want to reset ALL settings on ALL pages to defaults?');"/>
         </div></td>
      </tr>
   </table>
</form>

<?php

   //---------------------------------------
   // Process and output buffer to screen
   $out_buffer = ob_get_contents ();   // Retrieve buffer
   ob_end_clean ();                    // Clean (erase) the output buffer and turn off output buffering
   $out_buffer = do_shortcode ($out_buffer);
   echo $out_buffer;
   //---------------------------------------
}
//===========================================================================

//===========================================================================
//
// Get HTML of optin form
function JAY__get_signup_form ($admin_email="")
{
   global $g_JAY__plugin_directory_url;

   $image_url = $g_JAY__plugin_directory_url . '/jay-bird-30x.png';

   $form_action = $_SERVER['REQUEST_URI'];

   $signup_form =<<<TTT
<div>
   <form method="post" action="{$form_action}">
     <table width="400" align="center" style="margin:0;background-color:gray;border-collapse: separate;" border="2" cellspacing="1" cellpadding="0">
       <tr>
         <td style="background: url({$image_url}) no-repeat 1% center #eeffee;padding:4px 0;font-family: Verdana, Arial, Helvetica, sans-serif;font-size: 16px;" colspan="2" align="center" valign="middle">
           <div align="center"><b style="color:#087bf9;">J</b>-Shortcodes notifications</div><div style="font-size:11px;">Receive the latest tips, tutorials, news, announcements</div>
         </td>
       </tr>
       <tr>
         <td style="background-color:white;padding:4px 0;" align="center" valign="middle">
           <div align="center">
             <input type="text" name="subscribe_email" value="{$admin_email}" size="40" maxlength="128" />
           </div>
         </td>
         <td style="background-color:white;padding:4px 0;" width="112" align="center" valign="middle">
           <div align="center">
             <input type="submit" name="button_subscribe_to_js_notifications" value="Subscribe" style="font-weight:bold;border:1px solid #a5a500;background-color:#ffffea;" />
           </div>
         </td>
       </tr>
     </table>
   </form>
</div>
TTT;

   return  $signup_form;
}
//===========================================================================
