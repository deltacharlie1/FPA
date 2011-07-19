/*!
 * jQuery Mouse Wheeling Ticker support plug-in v1.0.0
 *
 * @requires jQuery v1.4 or later
 *
 * Copyright (c) 2010 Andrey Feldman
 *
 * Licensed under the MIT license:
 *   http://www.opensource.org/licenses/mit-license.php
 */
 (function($) {
    $.fn.tickerFreez = function() {
        return this.each(function() {
			if ($(this).attr("tickerTimer"))
				clearTimeout($(this).attr("tickerTimer"));
			else
				clearTimeout($($(this).children().get(0)).attr("tickerTimer"));
		});
	};
    $.fn.tickerScroll = function() {
        return this.each(function() {
			var c = $(this);
			if (!c.attr("tickerHeight"))
				c = $(c.children().get(0));
			if ( c.scrollTop() < c.attr("tickerHeight") )
				c.scrollTop(c.scrollTop()+1);
			else
				c.scrollTop(1);

			c.attr("tickerTimer", setTimeout('$("#'+this.id+'").tickerScroll();', c.attr("tickerSpeed")));
		});
	};
    $.fn.ticker = function(sp, freez, turbo) {
        return this.each(function() {
			var el = $(this);
			el.css("overflow", "hidden");
			
			if (!!turbo) {
				var w = el.width();
				var pl = el.css("padding-left");
				var pr = el.css("padding-right");
				el.css("padding-left", "0");
				el.css("padding-right", "0");
				el.width(el.width());
				nC = $("<div></div>");
				nC.height("100%");
				nC.width(w);
				nC.html(el.html());
				nC.appendTo(el.html(""));
				el = nC;
				el.css("overflow-y", "scroll");
				el.css("overflow-x", "hidden");
			}

			var i = $("<div></div>");
			i.css({"overflow": "hidden", "zoom": "1"});
			i.html(el.html());
			i.appendTo(el.html(""));

			if (!!turbo) {
				el.width(2*el.width()-i.width());
				el.css("padding-left", pl);
				el.css("padding-right", pr);
			}

			el.attr("tickerHeight", i.height());
			if (el.attr("tickerHeight")==0) 
				return;

			el.height(el.height());
			var a = 0, h = el.height();
			while(h > a) {
				a += i.height();
				i.clone(true).appendTo(el);
			}

			if (!(sp && sp > 0)) 
				sp = 50;
			el.attr("tickerSpeed", sp);

			if (!!freez) 
				el.hover(function() {el.tickerFreez()}, function() {el.tickerScroll()});

			if (!el.attr("id"))	
				el.attr("id", "ticker_"+(new Date()).getTime());

			el.tickerScroll();
		});
    };
})(jQuery);
