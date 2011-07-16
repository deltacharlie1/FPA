/*
    Jay Shortcodes
    Collection of userful shortcodes for any Wordpress Theme, Blog or Website
    http://www.jshortcodes.com
*/

//===========================================================================
jQuery(document).ready(function()
{
    jQuery ("a.js-ga").css ("display", "none");
    // Simple version:
    // jQuery(".jaccordion").accordion({ collapsible: true, active:false });

    //--------------------------------------
    // ==== Jaccordion part
    // Detect which pane user wants to start active with.
    jQuery(".jaccordion").each (function(index)
        {
        active_pane = jQuery(this).attr("active_pane");
        if (active_pane == undefined)
            {
            active_pane = false;
            }
        else
            {
            active_pane = parseInt (active_pane);
            }

        if (typeof jQuery(this).accordion == 'undefined')
            {
            return;
            }

        jQuery(this).accordion({ collapsible: true, autoHeight: false, active: active_pane });
        });
    //--------------------------------------

    //--------------------------------------
    // ==== Jtabs part
    jQuery(".jtabs").each (function(index)
        {
        if (typeof jQuery(this).tabs == 'undefined')
            {
            return;
            }
        jQuery(this).tabs();
        });
    //--------------------------------------

    //--------------------------------------
    // ==== JGallery part
    jQuery(".jgallery ul").each (function(index)
        {
        if (index==0)
            {
            // Instantiate only one gallery per page, until GalleryView javascript will be modified to support multiple galleries per page.
            var ul_id  = jQuery(this).attr('id');
            var params = window[ul_id];

            jQuery(this).galleryView (params);

            // Setting wrapper CSS if requested.
            if (typeof params.jg_wrapper_css != 'undefined')
                {
                // Setting full CSS for wrapper override single elements settings (if present).
                // We're adding style to possibly existing style info (not overwriting it).
                var curr_style = jQuery(".gv-gallery").attr("style");
                jQuery(".gv-gallery").attr("style", curr_style + ';' + params.jg_wrapper_css);
                }

            // Setting frame CSS if requested.
            if (typeof params.jg_frame_css != 'undefined')
                {
                // Append specified style to frame wrapper.
                var curr_style = jQuery(".gv-frame .gv-img_wrap").attr("style");
                jQuery(".gv-frame .gv-img_wrap").attr("style", curr_style + ';' + params.jg_frame_css);
                }
            }
        else
            {
            jQuery(this).parent().html('<div style="border:2px solid red;padding:5px;background-color:yellow;margin:25px 0;width:400px;">NOTE: Only one gallery per page is currently supported.</div>');
            }
        });
    jQuery(".jgallery").each (function(index)
        {
        // Show gallery after it finished rendering.
//        jQuery(this).css({'visibility' : 'visible'});
// or
          jQuery(this).css({'display' : 'block'});
        });
    //--------------------------------------

});
//===========================================================================
