=== Plugin Name ===
Contributors: gesman
Donate link: http://www.jshortcodes.com/
Tags: shortcodes, short codes, jquery shortcodes, jquery tabs shortcodes, tabs shortcodes, jquery accordion shortcodes, accordion shortcodes, wordpress shortcodes, wordpress short codes, theme shortcodes, template shortcodes, short tags, wordpress image gallery, wordpress slideshow, wordpress image slider, wordpress gallery and slideshow plugin
Requires at least: 2.5
Tested up to: 3.1
Stable tag: trunk

J Shortcodes plugin offers collection of useful shortcodes to compliment and enrich any wordpress theme, blog and website.


== Description ==

J Shortcodes allows you to add custom buttons, content boxes, tabs and accordion panels, build call to action and information boxes.
You can choose color, size and shape for any of these elements.

J Shortcodes also gives you the power to define custom column layouts within any page, post or even text widget.
Fly above restrictions and boundaries of the chosen theme. No more need to struggle with custom templates or PHP code.
[jcolumns] shortcode allows you to define infinite number of columns with infinite combination of custom widths for each column.
Define number of columns and their widths in percentages or relative size with one simple model="..." parameter.

Let your creativity and visual presentation fly!


Custom buttons are defined with     `[jbutton] ...[/jbutton]`  shortcode.
Content boxes are defined with      `[jbox]    ...[/jbox]`     shortcode.
Custom columns are defined with     `[jcolumns]...[/jcolumns]` shortcode.
Jquery tabs are defined with        `[jtabs]...[/jtabs]` shortcode.
Jquery accordions are defined with  `[jaccordion]...[/jaccordion]` shortcode.

== Installation ==

1. Unzip plugin files and upload them under your '/wp-content/plugins/' directory. Resulted names will be:
   './wp-content/plugins/j-shortcode/*'

2. Activate plugin at "Plugins" administration page.


== Upgrade Notice ==

Upgrade normally via your Wordpress admin -> Plugins panel.


== Screenshots ==

1. Samples of custom buttons created with `[jbutton] ... [/jbutton]` shortcodes.
2. Samples of content and information boxes created with `[jbox] ... [/jbox]` shortcodes.
3. Samples of custom column layouts created with `[jcolumns] ... [/jcolumns]` shortcodes.
4. Samples of jquery tabs created with `[jtabs] ... [/jtabs]` shortcodes.
5. Samples of jquery accordions created with `[jaccordion] ... [/jaccordion]` shortcodes.


== Frequently Asked Questions ==

= What is the detailed syntax of J Shortcodes? =

Please see http://www.jshortcodes.com for detailed help and tutorials.

= Can you add to J Shortcodes *Blah Blah* feature? =

We constantly adding new features to J Shortcodes, please contact us with your idea at:
http://www.jshortcodes.com/contact/


== Changelog ==

= 1.405 =
* Added 'width' parameter to [jbox], [jtabs] and [jaccordion] shortcode.

= 1.404 =
* Update from beta to general release.

= 1.403 =
* [jgallery]: Added ability to specify physical file location for images - helps to create gallery quickly without specifying each image URL separately.
* [jgallery]: Added ability to specify regular expression pattern to define which images needs to be included into gallery. Helps to create subgallery from single location.

= 1.402 =
* Added [jgallery] shortcode allowing to easily create embedded galleries, slideshows as well as represent any number of posts as a custom slideshow gallery.
* Fixed bug in admin panel, preventing some browsers from saving settings.
* Optimized - added ability to exclude loading of unused libraries and optimize page loads.

= 1.305 =
* Fixed bug in [j-memberwing] shortcode. Now J-shortcodes can be fully integrated with [wordpress membership plugin MemberWing-X](http://www.memberwing.com/ "Wordpress membership plugin")

= 1.304 =
* Improved init/upgrade logic to make sure all settings are in tact.

= 1.303 =
* Fixed issue where reactivation of plugin won't upgrade settings
* Strip `<p>...</p>` tags around j shortcodes tags that prevented normal operation with some editor/themes combo.
* Fixed bug where wpautop filter adds `</p>...<p>` tags (in reversed order) around shortcode tag content.

= 1.301 =
* Added shortcodes to support Jquery accordion and tabs panels: [jaccordion], [jtabs].
* Added shortcodes allowing to embed content of any page or post into any other page, post or sidebar widget: [page id="123"]

= 1.220 =
* Implemented activation hook to properly update settings.
* Implemented support for nested shortcodes, allowing nesting tables, boxes and any other upcoming shortcodes up to unlimited levels
* Added `[j-memberwing]` shortcode to support [wordpress membership plugin MemberWing-X](http://www.memberwing.com/ "Wordpress membership plugin") allowing to show certain content only to premium members.

= 1.218 =
* Improved Admin UI

= 1.217 =
* Added ability to display J Shortcodes in sidebar widgets

= 1.216 =
* Settings panel created. wpautop enable/disable is now configurable. More settings are coming...

= 1.215 =
* Formatting fix: wpautop filter was left alone. Will be made optional and configurable in the next update.

= 1.214 =
* CSS/layout improvements, big fix.

= 1.212 =
* First public release

