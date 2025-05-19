/**
 * jQuery (PNG Fix)
 * Microsoft Internet Explorer 24bit PNG Fix
 *
 * The MIT License
 * 
 * Copyright (c) 2007 Paul Campbell (pauljamescampbell.co.uk)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * @param		Object
 * @return		Array
 */
(function($) {
	
	$.fn.pngfix = function(options) {
		
		// ECMA scope fix
		var elements 	= this;
		// Plug-in values
		var settings 	= $.extend({
			imageFixSrc: 	false
		}, options);
		
		if(!$.browser.msie || ($.browser.msie &&  $.browser.version >= 7)) {
			return(elements); // Kill
		}
		
		function setFilter(el, path, mode) {
			// Apply filter to element, setting the MSDN properties:
			//		:src
			//		:enabled
			//		:sizingMethod  
			var fs 			= el.attr("filters");
			var alpha 		= "DXImageTransform.Microsoft.AlphaImageLoader";
			if (fs[alpha]) {
				with (fs[alpha]) { 
					enabled = true;
					src = path; 
					sizingMethod = mode;
			 	}
			} else {
				el.css("filter", 'progid:' + alpha + '(enabled="true", sizingMethod="' + mode + '", src="' + path + '")');			
			}
		}
		
		function forceWidth(el) {
			if(el.css("width") == "auto" & el.css("height") == "auto") {
				// Only force width of element if it's set to auto
				el.css("width", el.attr("offsetWidth") + "px");
			}
		}
		
		// __APPLY__
		
		return(
			elements.each(function() {
				
				var el = $(this);
				
				if(el.attr("tagName").toUpperCase() == "IMG" && (/.png"?$/).test(el.attr("src"))) {
					
					if(!settings.imageFixSrc) {
						// Wrap the <img> in a <span> then apply style/filters, 
						// removing the <img> tag from the final render 
						el.wrap("<span></span>");
						var par = el.parent();
						par.css({
							height: 	el.height(),
							width: 		el.width(),
							display: 	"inline-block"
						});
						setFilter(par, el.attr("src"), "scale");
						el.remove();
					} else if((/.gif$/).test(settings.imageFixSrc)) {
						// Replace the current image with a transparent GIF
						// and apply the filter to the background of the 
						// <img> tag (not the preferred route)
						forceWidth(el);
						setFilter(el, el.attr("src"), "image");
						el.attr("src", settings.imageFixSrc);
					}
					
				} else {
					var bg = el.css("backgroundImage");
					var matches = bg.match(/^url\("(.*)"\)$/);
					if(matches.length) {
						// Elements with a PNG as a backgroundImage have the
						// filter applied with a sizing method relevant to the 
						// background repeat type
						forceWidth(el);
						el.css("backgroundImage", "none");
						
						// Restrict scaling methods to valid MSDN defintions (or one custom)
						if(el.css("backgroundRepeat").indexOf("repeat") > -1) {
							var sc = settings.repeatMethod == "repeat" ? "repeat" : "scale";
						} else {
							var sc = "crop";
						}
						setFilter(el, matches[1], sc);
						
						// IE peek-a-boo for internal links
						el.find("a").each(function() {
							$(this).css("position", "relative");
						});
					}
				}
				
				
			}) // __END__
		);
	}

})(jQuery)

// jQuery pngfix
$(function() {
	$("img[@src$=png],.iepngfix").pngfix();
});