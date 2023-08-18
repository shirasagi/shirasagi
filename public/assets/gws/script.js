//  Copyright (c) 2002 M.Inamori,All rights reserved.
//  Coded 2/26/02
//
//	sprintf()

function sprintf() {
	var argv = sprintf.arguments;
	var argc = argv.length;
	if(argc == 0)
		return "";
	var result = "";
	var format = argv[0];
	var format_length = format.length;
	
	var flag, width, precision;
	flag = 0;
	
	var index = 1;
	var mode = 0;
	var tmpresult;
	var buff;
	for(var i = 0; i < format_length; i++) {
		var c = format.charAt(i);
		switch(mode) {
		case 0:		//normal
			if(c == '%') {
				tmpresult = c;
				mode = 1;
				buff = "";
			}
			else
				result += c;
			break;
		case 1:		//after '%'
			if(c == '%') {
				result += c;
				mode = 0;
				break;
			}
			if(index >= argc)
				argv[argc++] = "";
			width = 0;
			precision = -1;
			switch(c) {
			case '-':
				flag |= 1;
				mode = 1;
				break;
			case '+':
				flag |= 2;
				mode = 1;
				break;
			case '0':
				flag |= 4;
				mode = 2;
				break;
			case ' ':
				flag |= 8;
				mode = 1;
				break;
			case '#':
				flag |= 16;
				mode = 1;
				break;
			case '1': case '2': case '3': case '4': case '5':
			case '6': case '7': case '8': case '9':
				width = parseInt(c);
				mode = 2;
				break;
			case '-':
				flag = 1;
				mode = 2;
				break;
			case '.':
				width = "";
				precision = 0;
				mode = 3;
				break;
			case 'd':
				result += toInteger(argv[index], flag, width, precision);
				index++;
				mode = 0;
				break;
			case 'f':
				result += toFloatingPoint(argv[index], flag, width, 6);
				index++;
				mode = 0;
				break;
			case 'e':
				result += toExponential(argv[index], flag, width, 6, 'e');
				index++;
				mode = 0;
				break;
			case 'E':
				result += toExponential(argv[index], flag, width, 6, 'E');
				index++;
				mode = 0;
				break;
			case 's':
				result += argv[index];
				index++;
				mode = 0;
				break;
			default:
				result += buff + c;
				mode = 0;
				break;
			}
			break;
		case 2:		//while defining width
			switch(c) {
			case '.':
				precision = 0;
				mode = 3;
				break;
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				width = width * 10 + parseInt(c);
				mode = 2;
				break;
			case 'd':
				result += toInteger(argv[index], flag, width, precision);
				index++;
				mode = 0;
				break;
			case 'f':
				result += toFloatingPoint(argv[index], flag, width, 6);
				index++;
				mode = 0;
				break;
			case 'e':
				result += toExponential(argv[index], flag, width, 6, 'e');
				index++;
				mode = 0;
				break;
			case 'E':
				result += toExponential(argv[index], flag, width, 6, 'E');
				index++;
				mode = 0;
				break;
			case 's':
				result += toFormatString(argv[index], width, precision);
				index++;
				mode = 0;
				break;
			default:
				result += buff + c;
				mode = 0;
				break;
			}
			break;
		case 3:		//while defining precision
			switch(c) {
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
				precision = precision * 10 + parseInt(c);
				break;
			case 'd':
				result += toInteger(argv[index], flag, width, precision);
				index++;
				mode = 0;
				break;
			case 'f':
				result += toFloatingPoint(argv[index], flag, width, precision);
				index++;
				mode = 0;
				break;
			case 'e':
				result += toExponential(argv[index], flag, width, precision, 'e');
				index++;
				mode = 0;
				break;
			case 'E':
				result += toExponential(argv[index], flag, width, precision, 'E');
				index++;
				mode = 0;
				break;
			case 's':
				result += toFormatString(argv[index], width, precision);
				index++;
				mode = 0;
				break;
			default:
				result += buff + c;
				mode = 0;
				break;
			}
			break;
		default:
			return "error";
		}
		
		if(mode)
			buff += c;
	}
	
	return result;
}

function toInteger(n, f, w, p) {
	if(typeof n != "number") {
		if(typeof n == "string") {
			n = parseFloat(n);
			if(isNaN(n))
				n = 0;
		}
		else
			n = 0;
	}
	
	var str = n.toString();
	
	//to integer if decimal
	if(-1 < n && n < 1)
		str = "0";
	else {
		if(n < 0)
			str = str.substring(1);
		var pos_e = str.indexOf('e');
		if(pos_e != -1) {		//指数
			var exp = parseInt(str.substring(pos_e + 2));
			var pos_dot = str.indexOf('.');
			if(pos_dot == -1) {
				str = str.substring(0, pos_e) + "000000000000000000000";
				exp -= 21;
			}
			else {
				str = str.substring(0, pos_dot)
							+ str.substring(pos_dot + 1, pos_e) + "00000";
				exp -= str.length - pos_dot;
			}
			for( ; exp; exp--)
				str += "0";
		}
		else {
			var pos_dot = str.indexOf('.');
			if(pos_dot != -1)
				str = str.substring(0, pos_dot);
		}
	}
	
	//精度
	var len = str.length;
	if(len < p) {
		var c = "0";
		for(var i = p - len; i; i--)
			str = c + str;
		len = p;
	}
	
	//フラグの処理
	return ProcFlag(str, f, w - len, n >= 0);
}

function toFloatingPoint(n, f, w, p) {
	if(typeof n != "number") {
		if(typeof n == "string") {
			n = parseFloat(n);
			if(isNaN(n))
				n = 0;
		}
		else
			n = 0;
	}
	
	var bpositive = (n >= 0);
	if(!bpositive)
		n = -n;
	
	str = toFloatingPoint2(n, f, p);
	
	//フラグの処理
	return ProcFlag(str, f, w - str.length, bpositive);
}

function toFloatingPoint2(n, f, p) {
	var str = n.toString();
	
	//to decimal if exponential
	var pos_e = str.indexOf('e');
	if(pos_e != -1) {
		var exp = parseInt(str.substring(pos_e + 1));
		if(exp > 0) {			//指数を整数に
			var pos_dot = str.indexOf('.');
			if(pos_dot == -1) {
				str = str.substring(0, pos_e) + "000000000000000000000";
				exp -= 21;
			}
			else {
				str = str.charAt(0) + str.substring(2, pos_e) + "00000";
				exp -= str.length - 1;
			}
			for( ; exp; exp--)
				str += "0";
		}
		else {					//指数を小数に
			var equive_p = exp + p;
			if(equive_p < -1)	//精度無し
				str = "0";
			else if(equive_p >= 0) {	//精度有り
				str = str.substring(0, pos_e);
				var pos_dot = str.indexOf(".");
				if(pos_dot != -1)
					str = str.charAt(0) + str.substring(2, pos_e);
				str = "000000" + str;
				for(exp += 7; exp; exp++)
					str = "0" + str;
				str = "0." + str;
			}
			else {				//微妙
				var tmp = parseFloat(str.substring(0, pos_e));
				if(tmp > 5) {	//切り上げ
					str = "0.00000";
					for(var i = exp + 7; i; i++)
						str += "0";
					str += "1";
				}
				else			//切捨て
					str = "0";
			}
		}
	}
	
	//精度で整形
	var len = str.length;
	var pos_dot = str.indexOf(".");
	if(pos_dot != -1) {
		var dec = len - pos_dot - 1;
		if(dec > p) {		//切る
			var tmp = parseFloat(str.charAt(pos_dot + p + 1)
									+ "." + str.substring(pos_dot + p + 2));
			if(tmp > 5) {	//切り上げ
				var i;
				if(n < 1) {
					i = 2;
					while(str.charAt(i) == "0")
						i++;
					tmp = (parseInt(str.substring(i, p + 2)) + 1).toString();
					if(tmp.length > p + 2 - i) {		//桁増
						if(i == 2)
							str = "1." + tmp.substring(1);
						else
							str = str.substring(0, i - 1) + tmp;
					}
					else
						str = str.substring(0, i) + tmp;
				}
				else {
					tmp = (parseInt(str.substring(0, pos_dot) + str.substring(
								pos_dot + 1, pos_dot + p + 1)) + 1).toString();
					if(tmp.length > pos_dot + p)				//桁増
						str = tmp.substring(0, pos_dot + 1)
									+ "." +  tmp.substring(pos_dot + 1);
					else
						str = tmp.substring(0, pos_dot)
									+ "." + tmp.substring(pos_dot);
				}
			}
			else {		//切捨て
				str = str.substring(0, p ? pos_dot + p + 1 : pos_dot);
			}
		}
		else if(dec < p) {	//"0"を充填
			for(var i = p - dec; i; i--)
				str += "0";
		}
	}
	else {
		if(p) {
			str += ".0";
			for(var i = p - 1; i; i--)
				str += "0";
		}
	}
	
	return str;
}

function toExponential(n, f, w, p, e) {
	if(typeof n != "number") {
		if(typeof n == "string") {
			n = parseFloat(n);
			if(isNaN(n))
				n = 0;
		}
		else
			n = 0;
	}
	
	var bpositive = n >= 0;
	if(!bpositive)
		n = -n;
	
	var str = n.toString();
	var pos_dot = str.indexOf(".");
	var pos_e = str.indexOf("e");
	var type = ((pos_e != -1) << 1) + (pos_dot != -1);
	var exp;
	
	//仮数部と指数部に分ける
	if(type == 0) {			//整数
		if(exp = str.length - 1)
			str = str.charAt(0) + "." + str.substring(pos_dot = 1);
	}
	else if(type == 1) {	//小数
		if(n > 10) {
			exp = pos_dot - 1;
			str = str.substring(0, 1) + "."
					+ str.substring(1, pos_dot) + str.substring(pos_dot + 1);
			pos_dot = 1;
		}
		else if(n > 1)
			exp = 0;
		else {
			for(var i = 2; ; i++) {
				if(str.charAt(i) != "0") {
					exp = 1 - i;
					str = str.charAt(i) + "." + str.substring(i + 1);
					break;
				}
			}
			pos_dot = 1;
		}
	}
	else {	//指数
		exp = parseInt(str.substring(pos_e + 1));
		str = str.substring(0, pos_e);
	}
	
	//仮数部の整形
	str = toFloatingPoint2(parseFloat(str), f, p);
	
	//指数部の整形
	if(exp >= 0)
		str += e + (exp < 10 ? "+0" : "+") + exp;
	else
		str += e + (exp > -10 ? "-0" + (-exp) : exp);
	
	//フラグの処理
	str = ProcFlag(str, f, w - str.length, bpositive);
	
	return str;
}

function toFormatString(s, w, p) {
	if(typeof s != "string")
		s = s.toString();
	
	var len = s.length;
	if(p >= 0) {
		if(p < len) {
			s = s.substring(0, p);
			len = p;
		}
	}
	if(len < w) {
		var c = " ";
		for(var i = w - len; i; i--)
			s = c + s;
	}
	
	return s;
}

function ProcFlag(str, f, extra, b) {
	var minus = f & 1;
	var plus = f & 2;
	var space = f & 8;
	if(space)			//with ' '
		extra--;
	extra -= !b + plus > 0;
	if((f & 4) > 0 && !minus) {	//with 0 and not -
		if(extra > 0) {
			var c = "0";
			for(var i = extra; i; i--)
				str = c + str;
		}
		if(!b)
			str = "-" + str;
		else if(plus)
			str = "+" + str;
	}
	else {					//without 0 or with -
		if(!b)
			str = "-" + str;
		else if(plus)
			str = "+" + str;
		var c = " ";
		if(extra > 0) {
			var c = " ";
			if(minus)
				for(var i = extra; i; i--)
					str += c;
			else
				for(var i = extra; i; i--)
					str = c + str;
		}
	}
	if(space)
		str = " " + str;
	
	return str;
};
/*! gridster.js - v0.7.0 - 2017-03-27 - * https://dsmorse.github.io/gridster.js/ - Copyright (c) 2017 ducksboard; Licensed MIT */ !function(a,b){"use strict";"object"==typeof exports?module.exports=b(require("jquery")):"function"==typeof define&&define.amd?define("gridster-coords",["jquery"],b):a.GridsterCoords=b(a.$||a.jQuery)}(this,function(a){"use strict";function b(b){return b[0]&&a.isPlainObject(b[0])?this.data=b[0]:this.el=b,this.isCoords=!0,this.coords={},this.init(),this}var c=b.prototype;return c.init=function(){this.set(),this.original_coords=this.get()},c.set=function(a,b){var c=this.el;if(c&&!a&&(this.data=c.offset(),this.data.width=c[0].scrollWidth,this.data.height=c[0].scrollHeight),c&&a&&!b){var d=c.offset();this.data.top=d.top,this.data.left=d.left}var e=this.data;return void 0===e.left&&(e.left=e.x1),void 0===e.top&&(e.top=e.y1),this.coords.x1=e.left,this.coords.y1=e.top,this.coords.x2=e.left+e.width,this.coords.y2=e.top+e.height,this.coords.cx=e.left+e.width/2,this.coords.cy=e.top+e.height/2,this.coords.width=e.width,this.coords.height=e.height,this.coords.el=c||!1,this},c.update=function(b){if(!b&&!this.el)return this;if(b){var c=a.extend({},this.data,b);return this.data=c,this.set(!0,!0)}return this.set(!0),this},c.get=function(){return this.coords},c.destroy=function(){this.el.removeData("coords"),delete this.el},a.fn.coords=function(){if(this.data("coords"))return this.data("coords");var a=new b(this);return this.data("coords",a),a},b}),function(a,b){"use strict";"object"==typeof exports?module.exports=b(require("jquery")):"function"==typeof define&&define.amd?define("gridster-collision",["jquery","gridster-coords"],b):a.GridsterCollision=b(a.$||a.jQuery,a.GridsterCoords)}(this,function(a,b){"use strict";function c(b,c,e){this.options=a.extend(d,e),this.$element=b,this.last_colliders=[],this.last_colliders_coords=[],this.set_colliders(c),this.init()}var d={colliders_context:document.body,overlapping_region:"C"};c.defaults=d;var e=c.prototype;return e.init=function(){this.find_collisions()},e.overlaps=function(a,b){var c=!1,d=!1;return(b.x1>=a.x1&&b.x1<=a.x2||b.x2>=a.x1&&b.x2<=a.x2||a.x1>=b.x1&&a.x2<=b.x2)&&(c=!0),(b.y1>=a.y1&&b.y1<=a.y2||b.y2>=a.y1&&b.y2<=a.y2||a.y1>=b.y1&&a.y2<=b.y2)&&(d=!0),c&&d},e.detect_overlapping_region=function(a,b){var c="",d="";return a.y1>b.cy&&a.y1<b.y2&&(c="N"),a.y2>b.y1&&a.y2<b.cy&&(c="S"),a.x1>b.cx&&a.x1<b.x2&&(d="W"),a.x2>b.x1&&a.x2<b.cx&&(d="E"),c+d||"C"},e.calculate_overlapped_area_coords=function(b,c){var d=Math.max(b.x1,c.x1),e=Math.max(b.y1,c.y1);return a({left:d,top:e,width:Math.min(b.x2,c.x2)-d,height:Math.min(b.y2,c.y2)-e}).coords().get()},e.calculate_overlapped_area=function(a){return a.width*a.height},e.manage_colliders_start_stop=function(b,c,d){for(var e=this.last_colliders_coords,f=0,g=e.length;f<g;f++)a.inArray(e[f],b)===-1&&c.call(this,e[f]);for(var h=0,i=b.length;h<i;h++)a.inArray(b[h],e)===-1&&d.call(this,b[h])},e.find_collisions=function(b){for(var c=this,d=this.options.overlapping_region,e=[],f=[],g=this.colliders||this.$colliders,h=g.length,i=c.$element.coords().update(b||!1).get();h--;){var j=c.$colliders?a(g[h]):g[h],k=j.isCoords?j:j.coords(),l=k.get();if(c.overlaps(i,l)){var m=c.detect_overlapping_region(i,l);if(m===d||"all"===d){var n=c.calculate_overlapped_area_coords(i,l),o=c.calculate_overlapped_area(n);if(0!==o){var p={area:o,area_coords:n,region:m,coords:l,player_coords:i,el:j};c.options.on_overlap&&c.options.on_overlap.call(this,p),e.push(k),f.push(p)}}}}return(c.options.on_overlap_stop||c.options.on_overlap_start)&&this.manage_colliders_start_stop(e,c.options.on_overlap_start,c.options.on_overlap_stop),this.last_colliders_coords=e,f},e.get_closest_colliders=function(a){var b=this.find_collisions(a);return b.sort(function(a,b){return"C"===a.region&&"C"===b.region?a.coords.y1<b.coords.y1||a.coords.x1<b.coords.x1?-1:1:(a.area,b.area,1)}),b},e.set_colliders=function(b){"string"==typeof b||b instanceof a?this.$colliders=a(b,this.options.colliders_context).not(this.$element):this.colliders=a(b)},a.fn.collision=function(a,b){return new c(this,a,b)},c}),function(a,b){"use strict";a.delay=function(a,b){var c=Array.prototype.slice.call(arguments,2);return setTimeout(function(){return a.apply(null,c)},b)},a.debounce=function(a,b,c){var d;return function(){var e=this,f=arguments,g=function(){d=null,c||a.apply(e,f)};c&&!d&&a.apply(e,f),clearTimeout(d),d=setTimeout(g,b)}},a.throttle=function(a,b){var c,d,e,f,g,h,i=debounce(function(){g=f=!1},b);return function(){c=this,d=arguments;var j=function(){e=null,g&&a.apply(c,d),i()};return e||(e=setTimeout(j,b)),f?g=!0:h=a.apply(c,d),i(),f=!0,h}}}(window),function(a,b){"use strict";"object"==typeof exports?module.exports=b(require("jquery")):"function"==typeof define&&define.amd?define("gridster-draggable",["jquery"],b):a.GridsterDraggable=b(a.$||a.jQuery)}(this,function(a){"use strict";function b(b,d){this.options=a.extend({},c,d),this.$document=a(document),this.$container=a(b),this.$scroll_container=this.options.scroll_container===window?a(window):this.$container.closest(this.options.scroll_container),this.is_dragging=!1,this.player_min_left=0+this.options.offset_left,this.player_min_top=0+this.options.offset_top,this.id=i(),this.ns=".gridster-draggable-"+this.id,this.init()}var c={items:"li",distance:1,limit:{width:!0,height:!1},offset_left:0,autoscroll:!0,ignore_dragging:["INPUT","TEXTAREA","SELECT","BUTTON"],handle:null,container_width:0,move_element:!0,helper:!1,remove_helper:!0},d=a(window),e={x:"left",y:"top"},f=!!("ontouchstart"in window),g=function(a){return a.charAt(0).toUpperCase()+a.slice(1)},h=0,i=function(){return++h+""};b.defaults=c;var j=b.prototype;return j.init=function(){var b=this.$container.css("position");this.calculate_dimensions(),this.$container.css("position","static"===b?"relative":b),this.disabled=!1,this.events(),d.bind(this.nsEvent("resize"),throttle(a.proxy(this.calculate_dimensions,this),200))},j.nsEvent=function(a){return(a||"")+this.ns},j.events=function(){this.pointer_events={start:this.nsEvent("touchstart")+" "+this.nsEvent("mousedown"),move:this.nsEvent("touchmove")+" "+this.nsEvent("mousemove"),end:this.nsEvent("touchend")+" "+this.nsEvent("mouseup")},this.$container.on(this.nsEvent("selectstart"),a.proxy(this.on_select_start,this)),this.$container.on(this.pointer_events.start,this.options.items,a.proxy(this.drag_handler,this)),this.$document.on(this.pointer_events.end,a.proxy(function(a){this.is_dragging=!1,this.disabled||(this.$document.off(this.pointer_events.move),this.drag_start&&this.on_dragstop(a))},this))},j.get_actual_pos=function(a){return a.position()},j.get_mouse_pos=function(a){if(a.originalEvent&&a.originalEvent.touches){var b=a.originalEvent;a=b.touches.length?b.touches[0]:b.changedTouches[0]}return{left:a.clientX,top:a.clientY}},j.get_offset=function(a){a.preventDefault();var b=this.get_mouse_pos(a),c=Math.round(b.left-this.mouse_init_pos.left),d=Math.round(b.top-this.mouse_init_pos.top),e=Math.round(this.el_init_offset.left+c-this.baseX+this.$scroll_container.scrollLeft()-this.scroll_container_offset_x),f=Math.round(this.el_init_offset.top+d-this.baseY+this.$scroll_container.scrollTop()-this.scroll_container_offset_y);return this.options.limit.width&&(e>this.player_max_left?e=this.player_max_left:e<this.player_min_left&&(e=this.player_min_left)),this.options.limit.height&&(f>this.player_max_top?f=this.player_max_top:f<this.player_min_top&&(f=this.player_min_top)),{position:{left:e,top:f},pointer:{left:b.left,top:b.top,diff_left:c+(this.$scroll_container.scrollLeft()-this.scroll_container_offset_x),diff_top:d+(this.$scroll_container.scrollTop()-this.scroll_container_offset_y)}}},j.get_drag_data=function(a){var b=this.get_offset(a);return b.$player=this.$player,b.$helper=this.helper?this.$helper:this.$player,b},j.set_limits=function(a){return a||(a=this.$container.width()),this.player_max_left=a-this.player_width-this.options.offset_left,this.player_max_top=this.options.container_height-this.player_height-this.options.offset_top,this.options.container_width=a,this},j.scroll_in=function(a,b){var c,d=e[a],f=50,h=30,i="scroll"+g(d),j="x"===a,k=j?this.scroller_width:this.scroller_height;c=this.$scroll_container===window?j?this.$scroll_container.width():this.$scroll_container.height():j?this.$scroll_container[0].scrollWidth:this.$scroll_container[0].scrollHeight;var l,m=j?this.$player.width():this.$player.height(),n=this.$scroll_container[i](),o=n,p=o+k,q=p-f,r=o+f,s=o+b.pointer[d],t=c-k+m;return s>=q&&(l=n+h)<t&&(this.$scroll_container[i](l),this["scroll_offset_"+a]+=h),s<=r&&(l=n-h)>0&&(this.$scroll_container[i](l),this["scroll_offset_"+a]-=h),this},j.manage_scroll=function(a){this.scroll_in("x",a),this.scroll_in("y",a)},j.calculate_dimensions=function(){this.scroller_height=this.$scroll_container.height(),this.scroller_width=this.$scroll_container.width()},j.drag_handler=function(b){if(!this.disabled&&(1===b.which||f)&&!this.ignore_drag(b)){var c=this,d=!0;return this.$player=a(b.currentTarget),this.el_init_pos=this.get_actual_pos(this.$player),this.mouse_init_pos=this.get_mouse_pos(b),this.offsetY=this.mouse_init_pos.top-this.el_init_pos.top,this.$document.on(this.pointer_events.move,function(a){var b=c.get_mouse_pos(a),e=Math.abs(b.left-c.mouse_init_pos.left),f=Math.abs(b.top-c.mouse_init_pos.top);return(e>c.options.distance||f>c.options.distance)&&(d?(d=!1,c.on_dragstart.call(c,a),!1):(c.is_dragging===!0&&c.on_dragmove.call(c,a),!1))}),!!f&&void 0}},j.on_dragstart=function(a){if(a.preventDefault(),this.is_dragging)return this;this.drag_start=this.is_dragging=!0;var b=this.$container.offset();return this.baseX=Math.round(b.left),this.baseY=Math.round(b.top),"clone"===this.options.helper?(this.$helper=this.$player.clone().appendTo(this.$container).addClass("helper"),this.helper=!0):this.helper=!1,this.scroll_container_offset_y=this.$scroll_container.scrollTop(),this.scroll_container_offset_x=this.$scroll_container.scrollLeft(),this.el_init_offset=this.$player.offset(),this.player_width=this.$player.width(),this.player_height=this.$player.height(),this.set_limits(this.options.container_width),this.options.start&&this.options.start.call(this.$player,a,this.get_drag_data(a)),!1},j.on_dragmove=function(a){var b=this.get_drag_data(a);this.options.autoscroll&&this.manage_scroll(b),this.options.move_element&&(this.helper?this.$helper:this.$player).css({position:"absolute",left:b.position.left,top:b.position.top});var c=this.last_position||b.position;return b.prev_position=c,this.options.drag&&this.options.drag.call(this.$player,a,b),this.last_position=b.position,!1},j.on_dragstop=function(a){var b=this.get_drag_data(a);return this.drag_start=!1,this.options.stop&&this.options.stop.call(this.$player,a,b),this.helper&&this.options.remove_helper&&this.$helper.remove(),!1},j.on_select_start=function(a){if(!this.disabled&&!this.ignore_drag(a))return!1},j.enable=function(){this.disabled=!1},j.disable=function(){this.disabled=!0},j.destroy=function(){this.disable(),this.$container.off(this.ns),this.$document.off(this.ns),d.off(this.ns),a.removeData(this.$container,"drag")},j.ignore_drag=function(b){return this.options.handle?!a(b.target).is(this.options.handle):a.isFunction(this.options.ignore_dragging)?this.options.ignore_dragging(b):this.options.resize?!a(b.target).is(this.options.items):a(b.target).is(this.options.ignore_dragging.join(", "))},a.fn.gridDraggable=function(a){return new b(this,a)},a.fn.dragg=function(c){return this.each(function(){a.data(this,"drag")||a.data(this,"drag",new b(this,c))})},b}),function(a,b){"use strict";"object"==typeof exports?module.exports=b(require("jquery"),require("./jquery.draggable.js"),require("./jquery.collision.js"),require("./jquery.coords.js"),require("./utils.js")):"function"==typeof define&&define.amd?define(["jquery","gridster-draggable","gridster-collision"],b):a.Gridster=b(a.$||a.jQuery,a.GridsterDraggable,a.GridsterCollision)}(this,function(a,b,c){"use strict";function d(b,c){this.options=a.extend(!0,{},g,c),this.options.draggable=this.options.draggable||{},this.options.draggable=a.extend(!0,{},this.options.draggable,{scroll_container:this.options.scroll_container}),this.$el=a(b),this.$scroll_container=this.options.scroll_container===window?a(window):this.$el.closest(this.options.scroll_container),this.$wrapper=this.$el.parent(),this.$widgets=this.$el.children(this.options.widget_selector).addClass("gs-w"),this.$changed=a([]),this.w_queue={},this.is_responsive()?this.min_widget_width=this.get_responsive_col_width():this.min_widget_width=this.options.widget_base_dimensions[0],this.min_widget_height=this.options.widget_base_dimensions[1],this.is_resizing=!1,this.min_col_count=this.options.min_cols,this.prev_col_count=this.min_col_count,this.generated_stylesheets=[],this.$style_tags=a([]),typeof this.options.limit==typeof!0&&(console.log("limit: bool is deprecated, consider using limit: { width: boolean, height: boolean} instead"),this.options.limit={width:this.options.limit,height:this.options.limit}),this.options.auto_init&&this.init()}function e(a){for(var b=["col","row","size_x","size_y"],c={},d=0,e=b.length;d<e;d++){var f=b[d];if(!(f in a))throw new Error("Not exists property `"+f+"`");var g=a[f];if(!g||isNaN(g))throw new Error("Invalid value of `"+f+"` property");c[f]=+g}return c}var f=a(window),g={namespace:"",widget_selector:"li",static_class:"static",widget_margins:[10,10],widget_base_dimensions:[400,225],extra_rows:0,extra_cols:0,min_cols:1,max_cols:1/0,limit:{width:!0,height:!1},min_rows:1,max_rows:15,autogenerate_stylesheet:!0,avoid_overlapped_widgets:!0,auto_init:!0,center_widgets:!1,responsive_breakpoint:!1,scroll_container:window,shift_larger_widgets_down:!0,move_widgets_down_only:!1,shift_widgets_up:!0,show_element:function(a,b){b?a.fadeIn(b):a.fadeIn()},hide_element:function(a,b){b?a.fadeOut(b):a.fadeOut()},serialize_params:function(a,b){return{col:b.col,row:b.row,size_x:b.size_x,size_y:b.size_y}},collision:{wait_for_mouseup:!1},draggable:{items:".gs-w:not(.static)",distance:4,ignore_dragging:b.defaults.ignore_dragging.slice(0)},resize:{enabled:!1,axes:["both"],handle_append_to:"",handle_class:"gs-resize-handle",max_size:[1/0,1/0],min_size:[1,1]},ignore_self_occupied:!1};d.defaults=g,d.generated_stylesheets=[],d.sort_by_row_asc=function(b){return b=b.sort(function(b,c){return b.row||(b=a(b).coords().grid,c=a(c).coords().grid),b=e(b),c=e(c),b.row>c.row?1:-1})},d.sort_by_row_and_col_asc=function(a){return a=a.sort(function(a,b){return a=e(a),b=e(b),a.row>b.row||a.row===b.row&&a.col>b.col?1:-1})},d.sort_by_col_asc=function(a){return a=a.sort(function(a,b){return a=e(a),b=e(b),a.col>b.col?1:-1})},d.sort_by_row_desc=function(a){return a=a.sort(function(a,b){return a=e(a),b=e(b),a.row+a.size_y<b.row+b.size_y?1:-1})};var h=d.prototype;return h.init=function(){this.options.resize.enabled&&this.setup_resize(),this.generate_grid_and_stylesheet(),this.get_widgets_from_DOM(),this.set_dom_grid_height(),this.set_dom_grid_width(),this.$wrapper.addClass("ready"),this.draggable(),this.options.resize.enabled&&this.resizable(),this.options.center_widgets&&setTimeout(a.proxy(function(){this.center_widgets()},this),0),f.bind("resize.gridster",throttle(a.proxy(this.recalculate_faux_grid,this),200))},h.disable=function(){return this.$wrapper.find(".player-revert").removeClass("player-revert"),this.drag_api.disable(),this},h.enable=function(){return this.drag_api.enable(),this},h.disable_resize=function(){return this.$el.addClass("gs-resize-disabled"),this.resize_api.disable(),this},h.enable_resize=function(){return this.$el.removeClass("gs-resize-disabled"),this.resize_api.enable(),this},h.add_widget=function(b,c,d,e,f,g,h,i){var j;if(c||(c=1),d||(d=1),e||f)j={col:e,row:f,size_x:c,size_y:d},this.options.avoid_overlapped_widgets&&this.empty_cells(e,f,c,d);else if((j=this.next_position(c,d))===!1)return!1;var k=a(b).attr({"data-col":j.col,"data-row":j.row,"data-sizex":c,"data-sizey":d}).addClass("gs-w").appendTo(this.$el).hide();this.$widgets=this.$widgets.add(k),this.$changed=this.$changed.add(k),this.register_widget(k);var l=parseInt(j.row)+(parseInt(j.size_y)-1);return this.rows<l&&this.add_faux_rows(l-this.rows),g&&this.set_widget_max_size(k,g),h&&this.set_widget_min_size(k,h),this.set_dom_grid_width(),this.set_dom_grid_height(),this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0]),this.options.center_widgets&&setTimeout(a.proxy(function(){this.center_widgets()},this),0),this.options.show_element.call(this,k,i),k},h.set_widget_min_size=function(a,b){if(a="number"==typeof a?this.$widgets.eq(a):a,!a.length)return this;var c=a.data("coords").grid;return c.min_size_x=b[0],c.min_size_y=b[1],this},h.set_widget_max_size=function(a,b){if(a="number"==typeof a?this.$widgets.eq(a):a,!a.length)return this;var c=a.data("coords").grid;return c.max_size_x=b[0],c.max_size_y=b[1],this},h.add_resize_handle=function(b){var c=this.options.resize.handle_append_to?a(this.options.resize.handle_append_to,b):b;return 0===c.children("span[class~='"+this.resize_handle_class+"']").length&&a(this.resize_handle_tpl).appendTo(c),this},h.resize_widget=function(a,b,c,d){var e=a.coords().grid;this.is_resizing=!0,b||(b=e.size_x),c||(c=e.size_y),this.is_valid_row(e.row,c)||this.add_faux_rows(Math.max(this.calculate_highest_row(e.row,c)-this.rows,0)),this.is_valid_col(e.col,c)||this.add_faux_cols(Math.max(this.calculate_highest_row(e.col,b)-this.cols,0));var f={col:e.col,row:e.row,size_x:b,size_y:c};return this.mutate_widget_in_gridmap(a,e,f),this.set_dom_grid_height(),this.set_dom_grid_width(),d&&d.call(this,f.size_x,f.size_y),this.is_resizing=!1,a},h.expand_widget=function(b,c,d,e,f){var g=b.coords().grid,h=Math.floor((a(window).width()-2*this.options.widget_margins[0])/this.min_widget_width);c=c||Math.min(h,this.cols),d||(d=g.size_y);var i=g.size_y;b.attr("pre_expand_col",g.col),b.attr("pre_expand_sizex",g.size_x),b.attr("pre_expand_sizey",g.size_y);var j=e||1;d>i&&this.add_faux_rows(Math.max(d-i,0));var k={col:j,row:g.row,size_x:c,size_y:d};return this.mutate_widget_in_gridmap(b,g,k),this.set_dom_grid_height(),this.set_dom_grid_width(),f&&f.call(this,k.size_x,k.size_y),b},h.collapse_widget=function(a,b){var c=a.coords().grid,d=parseInt(a.attr("pre_expand_sizex")),e=parseInt(a.attr("pre_expand_sizey")),f=parseInt(a.attr("pre_expand_col")),g={col:f,row:c.row,size_x:d,size_y:e};return this.mutate_widget_in_gridmap(a,c,g),this.set_dom_grid_height(),this.set_dom_grid_width(),b&&b.call(this,g.size_x,g.size_y),a},h.fit_to_content=function(a,b,c,d){var e=a.coords().grid,f=this.$wrapper.width(),g=this.$wrapper.height(),h=this.options.widget_base_dimensions[0]+2*this.options.widget_margins[0],i=this.options.widget_base_dimensions[1]+2*this.options.widget_margins[1],j=Math.ceil((f+2*this.options.widget_margins[0])/h),k=Math.ceil((g+2*this.options.widget_margins[1])/i),l={col:e.col,row:e.row,size_x:Math.min(b,j),size_y:Math.min(c,k)};return this.mutate_widget_in_gridmap(a,e,l),this.set_dom_grid_height(),this.set_dom_grid_width(),d&&d.call(this,l.size_x,l.size_y),a},h.center_widgets=debounce(function(){var b,c=this.$wrapper.width();b=this.is_responsive()?this.get_responsive_col_width():this.options.widget_base_dimensions[0]+2*this.options.widget_margins[0];var d=2*Math.floor(Math.max(Math.floor(c/b),this.min_col_count)/2);this.options.min_cols=d,this.options.max_cols=d,this.options.extra_cols=0,this.set_dom_grid_width(d),this.cols=d;var e=(d-this.prev_col_count)/2;return e<0?(this.get_min_col()>e*-1?this.shift_cols(e):this.resize_widget_dimensions(this.options),setTimeout(a.proxy(function(){this.resize_widget_dimensions(this.options)},this),0)):e>0?(this.resize_widget_dimensions(this.options),setTimeout(a.proxy(function(){this.shift_cols(e)},this),0)):(this.resize_widget_dimensions(this.options),setTimeout(a.proxy(function(){this.resize_widget_dimensions(this.options)},this),0)),this.prev_col_count=d,this},200),h.get_min_col=function(){return Math.min.apply(Math,this.$widgets.map(a.proxy(function(b,c){return this.get_cells_occupied(a(c).coords().grid).cols},this)).get())},h.shift_cols=function(b){var c=this.$widgets.map(a.proxy(function(b,c){var d=a(c);return this.dom_to_coords(d)},this));c=d.sort_by_row_and_col_asc(c),c.each(a.proxy(function(c,d){var e=a(d.el),f=e.coords().grid,g=parseInt(e.attr("data-col")),h={col:Math.max(Math.round(g+b),1),row:f.row,size_x:f.size_x,size_y:f.size_y};setTimeout(a.proxy(function(){this.mutate_widget_in_gridmap(e,f,h)},this),0)},this))},h.mutate_widget_in_gridmap=function(b,c,d){var e=c.size_y,f=this.get_cells_occupied(c),g=this.get_cells_occupied(d),h=[];a.each(f.cols,function(b,c){a.inArray(c,g.cols)===-1&&h.push(c)});var i=[];a.each(g.cols,function(b,c){a.inArray(c,f.cols)===-1&&i.push(c)});var j=[];a.each(f.rows,function(b,c){a.inArray(c,g.rows)===-1&&j.push(c)});var k=[];if(a.each(g.rows,function(b,c){a.inArray(c,f.rows)===-1&&k.push(c)}),this.remove_from_gridmap(c),i.length){var l=[d.col,d.row,d.size_x,Math.min(e,d.size_y),b];this.empty_cells.apply(this,l)}if(k.length){var m=[d.col,d.row,d.size_x,d.size_y,b];this.empty_cells.apply(this,m)}if(c.col=d.col,c.row=d.row,c.size_x=d.size_x,c.size_y=d.size_y,this.add_to_gridmap(d,b),b.removeClass("player-revert"),this.update_widget_dimensions(b,d),this.options.shift_widgets_up){if(h.length){var n=[h[0],d.row,h[h.length-1]-h[0]+1,Math.min(e,d.size_y),b];this.remove_empty_cells.apply(this,n)}if(j.length){var o=[d.col,d.row,d.size_x,d.size_y,b];this.remove_empty_cells.apply(this,o)}}return this.move_widget_up(b),this},h.empty_cells=function(b,c,d,e,f){return this.widgets_below({col:b,row:c-e,size_x:d,size_y:e}).not(f).each(a.proxy(function(b,d){var f=a(d),g=f.coords().grid;if(g.row<=c+e-1){var h=c+e-g.row;this.move_widget_down(f,h)}},this)),this.is_resizing||this.set_dom_grid_height(),this},h.remove_empty_cells=function(b,c,d,e,f){return this.widgets_below({col:b,row:c,size_x:d,size_y:e}).not(f).each(a.proxy(function(b,c){this.move_widget_up(a(c),e)},this)),this.set_dom_grid_height(),this},h.next_position=function(a,b){a||(a=1),b||(b=1);for(var c,e=this.gridmap,f=e.length,g=[],h=1;h<f;h++){c=e[h].length;for(var i=1;i<=c;i++){this.can_move_to({size_x:a,size_y:b},h,i)&&g.push({col:h,row:i,size_y:b,size_x:a})}}return!!g.length&&d.sort_by_row_and_col_asc(g)[0]},h.remove_by_grid=function(a,b){var c=this.is_widget(a,b);c&&this.remove_widget(c)},h.remove_widget=function(b,c,d){var e=b instanceof a?b:a(b);if(0===e.length)return this;var f=e.coords().grid;if(void 0===f)return this;a.isFunction(c)&&(d=c,c=!1),this.cells_occupied_by_placeholder={},this.$widgets=this.$widgets.not(e);var g=this.widgets_below(e);return this.remove_from_gridmap(f),this.options.hide_element.call(this,e,a.proxy(function(){e.remove(),c||g.each(a.proxy(function(b,c){this.move_widget_up(a(c),f.size_y)},this)),this.set_dom_grid_height(),d&&d.call(this,b)},this)),this},h.remove_all_widgets=function(b){return this.$widgets.each(a.proxy(function(a,c){this.remove_widget(c,!0,b)},this)),this},h.serialize=function(b){b||(b=this.$widgets);var c=[];return b.each(a.proxy(function(b,d){var e=a(d);void 0!==e.coords().grid&&c.push(this.options.serialize_params(e,e.coords().grid))},this)),c},h.serialize_changed=function(){return this.serialize(this.$changed)},h.dom_to_coords=function(a){return{col:parseInt(a.attr("data-col"),10),row:parseInt(a.attr("data-row"),10),size_x:parseInt(a.attr("data-sizex"),10)||1,size_y:parseInt(a.attr("data-sizey"),10)||1,max_size_x:parseInt(a.attr("data-max-sizex"),10)||!1,max_size_y:parseInt(a.attr("data-max-sizey"),10)||!1,min_size_x:parseInt(a.attr("data-min-sizex"),10)||!1,min_size_y:parseInt(a.attr("data-min-sizey"),10)||!1,el:a}},h.register_widget=function(b){var c=b instanceof a,d=c?this.dom_to_coords(b):b,e=!1;c||(b=d.el);var f=this.can_go_widget_up(d);return this.options.shift_widgets_up&&f&&(d.row=f,b.attr("data-row",f),this.$el.trigger("gridster:positionchanged",[d]),e=!0),this.options.avoid_overlapped_widgets&&!this.can_move_to({size_x:d.size_x,size_y:d.size_y},d.col,d.row)&&(a.extend(d,this.next_position(d.size_x,d.size_y)),b.attr({"data-col":d.col,"data-row":d.row,"data-sizex":d.size_x,"data-sizey":d.size_y}),e=!0),b.data("coords",b.coords()),b.data("coords").grid=d,this.add_to_gridmap(d,b),this.update_widget_dimensions(b,d),this.options.resize.enabled&&this.add_resize_handle(b),e},h.update_widget_position=function(a,b){return this.for_each_cell_occupied(a,function(a,c){if(!this.gridmap[a])return this;this.gridmap[a][c]=b}),this},h.update_widget_dimensions=function(a,b){var c=b.size_x*(this.is_responsive()?this.get_responsive_col_width():this.options.widget_base_dimensions[0])+(b.size_x-1)*this.options.widget_margins[0],d=b.size_y*this.options.widget_base_dimensions[1]+(b.size_y-1)*this.options.widget_margins[1];return a.data("coords").update({width:c,height:d}),a.attr({"data-col":b.col,"data-row":b.row,"data-sizex":b.size_x,"data-sizey":b.size_y}),this},h.update_widgets_dimensions=function(){return a.each(this.$widgets,a.proxy(function(b,c){var d=a(c).coords().grid;"object"==typeof d&&this.update_widget_dimensions(a(c),d)},this)),this},h.remove_from_gridmap=function(a){return this.update_widget_position(a,!1)},h.add_to_gridmap=function(a,b){this.update_widget_position(a,b||a.el)},h.draggable=function(){var b=this,c=a.extend(!0,{},this.options.draggable,{offset_left:this.options.widget_margins[0],offset_top:this.options.widget_margins[1],container_width:this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0],container_height:this.rows*this.min_widget_height+(this.rows+1)*this.options.widget_margins[0],limit:{width:this.options.limit.width,height:this.options.limit.height},start:function(c,d){b.$widgets.filter(".player-revert").removeClass("player-revert"),b.$player=a(this),b.$helper=a(d.$helper),b.helper=!b.$helper.is(b.$player),b.on_start_drag.call(b,c,d),b.$el.trigger("gridster:dragstart")},stop:function(a,c){b.on_stop_drag.call(b,a,c),b.$el.trigger("gridster:dragstop")},drag:throttle(function(a,c){b.on_drag.call(b,a,c),b.$el.trigger("gridster:drag")},60)});this.drag_api=this.$el.dragg(c).data("drag")},h.resizable=function(){return this.resize_api=this.$el.gridDraggable({items:"."+this.options.resize.handle_class,offset_left:this.options.widget_margins[0],container_width:this.container_width,move_element:!1,resize:!0,limit:{width:this.options.max_cols!==1/0||this.limit.width,height:this.options.max_rows!==1/0||this.limit.height},scroll_container:this.options.scroll_container,start:a.proxy(this.on_start_resize,this),stop:a.proxy(function(b,c){delay(a.proxy(function(){this.on_stop_resize(b,c)},this),120)},this),drag:throttle(a.proxy(this.on_resize,this),60)}),this},h.setup_resize=function(){this.resize_handle_class=this.options.resize.handle_class;var b=this.options.resize.axes,c='<span class="'+this.resize_handle_class+" "+this.resize_handle_class+'-{type}" />';return this.resize_handle_tpl=a.map(b,function(a){return c.replace("{type}",a)}).join(""),a.isArray(this.options.draggable.ignore_dragging)&&this.options.draggable.ignore_dragging.push("."+this.resize_handle_class),this},h.on_start_drag=function(b,c){this.$helper.add(this.$player).add(this.$wrapper).addClass("dragging"),this.highest_col=this.get_highest_occupied_cell().col,this.$player.addClass("player"),this.player_grid_data=this.$player.coords().grid,this.placeholder_grid_data=a.extend({},this.player_grid_data),this.get_highest_occupied_cell().row+this.player_grid_data.size_y<=this.options.max_rows&&this.set_dom_grid_height(this.$el.height()+this.player_grid_data.size_y*this.min_widget_height),this.set_dom_grid_width(this.cols);var d=this.player_grid_data.size_x,e=this.cols-this.highest_col;this.options.max_cols===1/0&&e<=d&&this.add_faux_cols(Math.min(d-e,1));var f=this.faux_grid,g=this.$player.data("coords").coords;this.cells_occupied_by_player=this.get_cells_occupied(this.player_grid_data),this.cells_occupied_by_placeholder=this.get_cells_occupied(this.placeholder_grid_data),this.last_cols=[],this.last_rows=[],this.collision_api=this.$helper.collision(f,this.options.collision),this.$preview_holder=a("<"+this.$player.get(0).tagName+" />",{class:"preview-holder","data-row":this.$player.attr("data-row"),"data-col":this.$player.attr("data-col"),css:{width:g.width,height:g.height}}).appendTo(this.$el),this.options.draggable.start&&this.options.draggable.start.call(this,b,c)},h.on_drag=function(a,b){if(null===this.$player)return!1;var c=this.options.widget_margins,d=this.$preview_holder.attr("data-col"),e=this.$preview_holder.attr("data-row"),f={left:b.position.left+this.baseX-c[0]*d,top:b.position.top+this.baseY-c[1]*e};if(this.options.max_cols===1/0){this.placeholder_grid_data.col+this.placeholder_grid_data.size_x-1>=this.cols-1&&this.options.max_cols>=this.cols+1&&(this.add_faux_cols(1),this.set_dom_grid_width(this.cols+1),this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0])),this.collision_api.set_colliders(this.faux_grid)}this.colliders_data=this.collision_api.get_closest_colliders(f),this.on_overlapped_column_change(this.on_start_overlapping_column,this.on_stop_overlapping_column),this.on_overlapped_row_change(this.on_start_overlapping_row,this.on_stop_overlapping_row),this.helper&&this.$player&&this.$player.css({left:b.position.left,top:b.position.top}),this.options.draggable.drag&&this.options.draggable.drag.call(this,a,b)},h.on_stop_drag=function(a,b){this.$helper.add(this.$player).add(this.$wrapper).removeClass("dragging");var c=this.options.widget_margins,d=this.$preview_holder.attr("data-col"),e=this.$preview_holder.attr("data-row");b.position.left=b.position.left+this.baseX-c[0]*d,b.position.top=b.position.top+this.baseY-c[1]*e,this.colliders_data=this.collision_api.get_closest_colliders(b.position),this.on_overlapped_column_change(this.on_start_overlapping_column,this.on_stop_overlapping_column),this.on_overlapped_row_change(this.on_start_overlapping_row,this.on_stop_overlapping_row),this.$changed=this.$changed.add(this.$player);var f=this.placeholder_grid_data.el.coords().grid;f.col===this.placeholder_grid_data.col&&f.row===this.placeholder_grid_data.row||(this.update_widget_position(f,!1),this.options.collision.wait_for_mouseup&&this.for_each_cell_occupied(this.placeholder_grid_data,function(a,b){if(this.is_widget(a,b)){var c=this.placeholder_grid_data.row+this.placeholder_grid_data.size_y,d=parseInt(this.gridmap[a][b][0].getAttribute("data-row")),e=c-d;!this.move_widget_down(this.is_widget(a,b),e)&&this.set_placeholder(this.placeholder_grid_data.el.coords().grid.col,this.placeholder_grid_data.el.coords().grid.row)}})),this.cells_occupied_by_player=this.get_cells_occupied(this.placeholder_grid_data);var g=this.placeholder_grid_data.col,h=this.placeholder_grid_data.row;this.set_cells_player_occupies(g,h),this.$player.coords().grid.row=h,this.$player.coords().grid.col=g,this.$player.addClass("player-revert").removeClass("player").attr({"data-col":g,"data-row":h}).css({left:"",top:""}),this.options.draggable.stop&&this.options.draggable.stop.call(this,a,b),this.$preview_holder.remove(),this.$player=null,this.$helper=null,this.placeholder_grid_data={},this.player_grid_data={},this.cells_occupied_by_placeholder={},this.cells_occupied_by_player={},this.w_queue={},this.set_dom_grid_height(),this.set_dom_grid_width(),this.options.max_cols===1/0&&this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0])},h.on_start_resize=function(b,c){this.$resized_widget=c.$player.closest(".gs-w"),this.resize_coords=this.$resized_widget.coords(),this.resize_wgd=this.resize_coords.grid,this.resize_initial_width=this.resize_coords.coords.width,this.resize_initial_height=this.resize_coords.coords.height,this.resize_initial_sizex=this.resize_coords.grid.size_x,this.resize_initial_sizey=this.resize_coords.grid.size_y,this.resize_initial_col=this.resize_coords.grid.col,this.resize_last_sizex=this.resize_initial_sizex,this.resize_last_sizey=this.resize_initial_sizey,
this.resize_max_size_x=Math.min(this.resize_wgd.max_size_x||this.options.resize.max_size[0],this.options.max_cols-this.resize_initial_col+1),this.resize_max_size_y=this.resize_wgd.max_size_y||this.options.resize.max_size[1],this.resize_min_size_x=this.resize_wgd.min_size_x||this.options.resize.min_size[0]||1,this.resize_min_size_y=this.resize_wgd.min_size_y||this.options.resize.min_size[1]||1,this.resize_initial_last_col=this.get_highest_occupied_cell().col,this.set_dom_grid_width(this.cols),this.resize_dir={right:c.$player.is("."+this.resize_handle_class+"-x"),bottom:c.$player.is("."+this.resize_handle_class+"-y")},this.is_responsive()||this.$resized_widget.css({"min-width":this.options.widget_base_dimensions[0],"min-height":this.options.widget_base_dimensions[1]});var d=this.$resized_widget.get(0).tagName;this.$resize_preview_holder=a("<"+d+" />",{class:"preview-holder resize-preview-holder","data-row":this.$resized_widget.attr("data-row"),"data-col":this.$resized_widget.attr("data-col"),css:{width:this.resize_initial_width,height:this.resize_initial_height}}).appendTo(this.$el),this.$resized_widget.addClass("resizing"),this.options.resize.start&&this.options.resize.start.call(this,b,c,this.$resized_widget),this.$el.trigger("gridster:resizestart")},h.on_stop_resize=function(b,c){this.$resized_widget.removeClass("resizing").css({width:"",height:"","min-width":"","min-height":""}),delay(a.proxy(function(){this.$resize_preview_holder.remove().css({"min-width":"","min-height":""}),this.options.resize.stop&&this.options.resize.stop.call(this,b,c,this.$resized_widget),this.$el.trigger("gridster:resizestop")},this),300),this.set_dom_grid_width(),this.set_dom_grid_height(),this.options.max_cols===1/0&&this.drag_api.set_limits(this.cols*this.min_widget_width)},h.on_resize=function(a,b){var c,d=b.pointer.diff_left,e=b.pointer.diff_top,f=this.is_responsive()?this.get_responsive_col_width():this.options.widget_base_dimensions[0],g=this.options.widget_base_dimensions[1],h=this.options.widget_margins[0],i=this.options.widget_margins[1],j=this.resize_max_size_x,k=this.resize_min_size_x,l=this.resize_max_size_y,m=this.resize_min_size_y,n=this.options.max_cols===1/0,o=Math.ceil(d/(f+2*h)-.2),p=Math.ceil(e/(g+2*i)-.2),q=Math.max(1,this.resize_initial_sizex+o),r=Math.max(1,this.resize_initial_sizey+p),s=Math.floor(this.container_width/this.min_widget_width-this.resize_initial_col+1),t=s*this.min_widget_width+(s-1)*h;q=Math.max(Math.min(q,j),k),q=Math.min(s,q),c=j*f+(q-1)*h;var u=Math.min(c,t),v=k*f+(q-1)*h;r=Math.max(Math.min(r,l),m);var w=l*g+(r-1)*i,x=m*g+(r-1)*i;if(this.resize_dir.right?r=this.resize_initial_sizey:this.resize_dir.bottom&&(q=this.resize_initial_sizex),n){var y=this.resize_initial_col+q-1;n&&this.resize_initial_last_col<=y&&(this.set_dom_grid_width(Math.max(y+1,this.cols)),this.cols<y&&this.add_faux_cols(y-this.cols))}var z={};!this.resize_dir.bottom&&(z.width=Math.max(Math.min(this.resize_initial_width+d,u),v)),!this.resize_dir.right&&(z.height=Math.max(Math.min(this.resize_initial_height+e,w),x)),this.$resized_widget.css(z),q===this.resize_last_sizex&&r===this.resize_last_sizey||(this.resize_widget(this.$resized_widget,q,r,!1),this.set_dom_grid_width(this.cols),this.$resize_preview_holder.css({width:"",height:""}).attr({"data-row":this.$resized_widget.attr("data-row"),"data-sizex":q,"data-sizey":r})),this.options.resize.resize&&this.options.resize.resize.call(this,a,b,this.$resized_widget),this.$el.trigger("gridster:resize"),this.resize_last_sizex=q,this.resize_last_sizey=r},h.on_overlapped_column_change=function(b,c){if(!this.colliders_data.length)return this;var d,e=this.get_targeted_columns(this.colliders_data[0].el.data.col),f=this.last_cols.length,g=e.length;for(d=0;d<g;d++)a.inArray(e[d],this.last_cols)===-1&&(b||a.noop).call(this,e[d]);for(d=0;d<f;d++)a.inArray(this.last_cols[d],e)===-1&&(c||a.noop).call(this,this.last_cols[d]);return this.last_cols=e,this},h.on_overlapped_row_change=function(b,c){if(!this.colliders_data.length)return this;var d,e=this.get_targeted_rows(this.colliders_data[0].el.data.row),f=this.last_rows.length,g=e.length;for(d=0;d<g;d++)a.inArray(e[d],this.last_rows)===-1&&(b||a.noop).call(this,e[d]);for(d=0;d<f;d++)a.inArray(this.last_rows[d],e)===-1&&(c||a.noop).call(this,this.last_rows[d]);this.last_rows=e},h.set_player=function(b,c,d){var e=this,f=!1,g=d?{col:b}:e.colliders_data[0].el.data,h=g.col,i=g.row||c;this.player_grid_data={col:h,row:i,size_y:this.player_grid_data.size_y,size_x:this.player_grid_data.size_x},this.cells_occupied_by_player=this.get_cells_occupied(this.player_grid_data),this.cells_occupied_by_placeholder=this.get_cells_occupied(this.placeholder_grid_data);var j=this.get_widgets_overlapped(this.player_grid_data),k=this.player_grid_data.size_y,l=this.player_grid_data.size_x,m=this.cells_occupied_by_placeholder,n=this;if(j.each(a.proxy(function(b,c){var d=a(c),e=d.coords().grid,g=m.cols[0]+l-1,o=m.rows[0]+k-1;if(d.hasClass(n.options.static_class))return!0;if(n.options.collision.wait_for_mouseup&&n.drag_api.is_dragging)n.placeholder_grid_data.col=h,n.placeholder_grid_data.row=i,n.cells_occupied_by_placeholder=n.get_cells_occupied(n.placeholder_grid_data),n.$preview_holder.attr({"data-row":i,"data-col":h});else if(e.size_x<=l&&e.size_y<=k)if(n.is_swap_occupied(m.cols[0],e.row,e.size_x,e.size_y)||n.is_player_in(m.cols[0],e.row)||n.is_in_queue(m.cols[0],e.row,d))if(n.is_swap_occupied(g,e.row,e.size_x,e.size_y)||n.is_player_in(g,e.row)||n.is_in_queue(g,e.row,d))if(n.is_swap_occupied(e.col,m.rows[0],e.size_x,e.size_y)||n.is_player_in(e.col,m.rows[0])||n.is_in_queue(e.col,m.rows[0],d))if(n.is_swap_occupied(e.col,o,e.size_x,e.size_y)||n.is_player_in(e.col,o)||n.is_in_queue(e.col,o,d))if(n.is_swap_occupied(m.cols[0],m.rows[0],e.size_x,e.size_y)||n.is_player_in(m.cols[0],m.rows[0])||n.is_in_queue(m.cols[0],m.rows[0],d))for(var p=0;p<l;p++)for(var q=0;q<k;q++){var r=m.cols[0]+p,s=m.rows[0]+q;if(!n.is_swap_occupied(r,s,e.size_x,e.size_y)&&!n.is_player_in(r,s)&&!n.is_in_queue(r,s,d)){f=n.queue_widget(r,s,d),p=l;break}}else n.options.move_widgets_down_only?j.each(a.proxy(function(b,c){var d=a(c);n.can_go_down(d)&&d.coords().grid.row===n.player_grid_data.row&&!n.is_in_queue(g,e.row,d)&&(n.move_widget_down(d,n.player_grid_data.size_y),n.set_placeholder(h,i))})):f=n.queue_widget(m.cols[0],m.rows[0],d);else f=n.queue_widget(e.col,o,d);else f=n.queue_widget(e.col,m.rows[0],d);else f=n.queue_widget(g,e.row,d);else n.options.move_widgets_down_only?j.each(a.proxy(function(b,c){var d=a(c);n.can_go_down(d)&&d.coords().grid.row===n.player_grid_data.row&&!n.is_in_queue(d.coords().grid.col,e.row,d)&&(n.move_widget_down(d,n.player_grid_data.size_y),n.set_placeholder(h,i))})):f=n.queue_widget(m.cols[0],e.row,d);else n.options.shift_larger_widgets_down&&!f&&j.each(a.proxy(function(b,c){var d=a(c);n.can_go_down(d)&&d.coords().grid.row===n.player_grid_data.row&&(n.move_widget_down(d,n.player_grid_data.size_y),n.set_placeholder(h,i))}));n.clean_up_changed()})),f&&this.can_placeholder_be_set(h,i,l,k)){for(var o in this.w_queue){var p=parseInt(o.split("_")[0]),q=parseInt(o.split("_")[1]);"full"!==this.w_queue[o]&&this.new_move_widget_to(this.w_queue[o],p,q)}this.set_placeholder(h,i)}if(!j.length){if(this.options.shift_widgets_up){var r=this.can_go_player_up(this.player_grid_data);r!==!1&&(i=r)}this.can_placeholder_be_set(h,i,l,k)&&this.set_placeholder(h,i)}return this.w_queue={},{col:h,row:i}},h.is_swap_occupied=function(a,b,c,d){for(var e=!1,f=0;f<c;f++)for(var g=0;g<d;g++){var h=a+f,i=b+g,j=h+"_"+i;if(this.is_occupied(h,i))e=!0;else if(j in this.w_queue){if("full"===this.w_queue[j]){e=!0;continue}var k=this.w_queue[j],l=k.coords().grid;this.is_widget_under_player(l.col,l.row)||delete this.w_queue[j]}i>parseInt(this.options.max_rows)&&(e=!0),h>parseInt(this.options.max_cols)&&(e=!0),this.is_player_in(h,i)&&(e=!0)}return e},h.can_placeholder_be_set=function(a,b,c,d){for(var e=!0,f=0;f<c;f++)for(var g=0;g<d;g++){var h=a+f,i=b+g,j=this.is_widget(h,i);i>parseInt(this.options.max_rows)&&(e=!1),h>parseInt(this.options.max_cols)&&(e=!1),this.is_occupied(h,i)&&!this.is_widget_queued_and_can_move(j)&&(e=!1)}return e},h.queue_widget=function(a,b,c){var d=c,e=d.coords().grid,f=a+"_"+b;if(f in this.w_queue)return!1;this.w_queue[f]=d;for(var g=0;g<e.size_x;g++)for(var h=0;h<e.size_y;h++){var i=a+g,j=b+h,k=i+"_"+j;k!==f&&(this.w_queue[k]="full")}return!0},h.is_widget_queued_and_can_move=function(a){var b=!1;if(a===!1)return!1;for(var c in this.w_queue)if("full"!==this.w_queue[c]&&this.w_queue[c].attr("data-col")===a.attr("data-col")&&this.w_queue[c].attr("data-row")===a.attr("data-row")){b=!0;for(var d=this.w_queue[c],e=parseInt(c.split("_")[0]),f=parseInt(c.split("_")[1]),g=d.coords().grid,h=0;h<g.size_x;h++)for(var i=0;i<g.size_y;i++){var j=e+h,k=f+i;this.is_player_in(j,k)&&(b=!1)}}return b},h.is_in_queue=function(a,b,c){var d=!1,e=a+"_"+b;if(e in this.w_queue)if("full"===this.w_queue[e])d=!0;else{var f=this.w_queue[e],g=f.coords().grid;this.is_widget_under_player(g.col,g.row)?this.w_queue[e].attr("data-col")===c.attr("data-col")&&this.w_queue[e].attr("data-row")===c.attr("data-row")?(delete this.w_queue[e],d=!1):d=!0:(delete this.w_queue[e],d=!1)}return d},h.widgets_constraints=function(b){var c=a([]),e=[],f=[];return b.each(a.proxy(function(b,d){var g=a(d),h=g.coords().grid;this.can_go_widget_up(h)?(c=c.add(g),e.push(h)):f.push(h)},this)),b.not(c),{can_go_up:d.sort_by_row_asc(e),can_not_go_up:d.sort_by_row_desc(f)}},h.manage_movements=function(b,c,d){return a.each(b,a.proxy(function(a,b){var e=b,f=e.el,g=this.can_go_widget_up(e);if(g)this.move_widget_to(f,g),this.set_placeholder(c,g+e.size_y);else{if(!this.can_go_player_up(this.player_grid_data)){var h=d+this.player_grid_data.size_y-e.row;this.can_go_down(f)&&(console.log("In Move Down!"),this.move_widget_down(f,h),this.set_placeholder(c,d))}}},this)),this},h.is_player=function(a,b){if(b&&!this.gridmap[a])return!1;var c=b?this.gridmap[a][b]:a;return c&&(c.is(this.$player)||c.is(this.$helper))},h.is_player_in=function(b,c){var d=this.cells_occupied_by_player||{};return a.inArray(b,d.cols)>=0&&a.inArray(c,d.rows)>=0},h.is_placeholder_in=function(b,c){var d=this.cells_occupied_by_placeholder||{};return this.is_placeholder_in_col(b)&&a.inArray(c,d.rows)>=0},h.is_placeholder_in_col=function(b){var c=this.cells_occupied_by_placeholder||[];return a.inArray(b,c.cols)>=0},h.is_empty=function(a,b){return void 0===this.gridmap[a]||void 0!==this.gridmap[a][b]&&this.gridmap[a][b]===!1},h.is_valid_col=function(a,b){return this.options.max_cols===1/0||this.cols>=this.calculate_highest_col(a,b)},h.is_valid_row=function(a,b){return this.rows>=this.calculate_highest_row(a,b)},h.calculate_highest_col=function(a,b){return a+(b||1)-1},h.calculate_highest_row=function(a,b){return a+(b||1)-1},h.is_occupied=function(b,c){return!!this.gridmap[b]&&(!this.is_player(b,c)&&(!!this.gridmap[b][c]&&(!this.options.ignore_self_occupied||this.$player.data()!==a(this.gridmap[b][c]).data())))},h.is_widget=function(a,b){var c=this.gridmap[a];return!!c&&(!!(c=c[b])&&c)},h.is_static=function(a,b){var c=this.gridmap[a];return!!c&&!(!(c=c[b])||!c.hasClass(this.options.static_class))},h.is_widget_under_player=function(a,b){return!!this.is_widget(a,b)&&this.is_player_in(a,b)},h.get_widgets_under_player=function(b){b||(b=this.cells_occupied_by_player||{cols:[],rows:[]});var c=a([]);return a.each(b.cols,a.proxy(function(d,e){a.each(b.rows,a.proxy(function(a,b){this.is_widget(e,b)&&(c=c.add(this.gridmap[e][b]))},this))},this)),c},h.set_placeholder=function(b,c){var d=a.extend({},this.placeholder_grid_data),e=b+d.size_x-1;e>this.cols&&(b-=e-b);var f=this.placeholder_grid_data.row<c,g=this.placeholder_grid_data.col!==b;if(this.placeholder_grid_data.col=b,this.placeholder_grid_data.row=c,this.cells_occupied_by_placeholder=this.get_cells_occupied(this.placeholder_grid_data),this.$preview_holder.attr({"data-row":c,"data-col":b}),this.options.shift_player_up){if(f||g){this.widgets_below({col:d.col,row:d.row,size_y:d.size_y,size_x:d.size_x}).each(a.proxy(function(b,c){var d=a(c),e=d.coords().grid,f=this.can_go_widget_up(e);f&&this.move_widget_to(d,f)},this))}var h=this.get_widgets_under_player(this.cells_occupied_by_placeholder);h.length&&h.each(a.proxy(function(b,e){var f=a(e);this.move_widget_down(f,c+d.size_y-f.data("coords").grid.row)},this))}},h.can_go_player_up=function(a){var b=a.row+a.size_y-1,c=!0,d=[],e=1e4,f=this.get_widgets_under_player();return this.for_each_column_occupied(a,function(a){var g=this.gridmap[a],h=b+1;for(d[a]=[];--h>0&&(this.is_empty(a,h)||this.is_player(a,h)||this.is_widget(a,h)&&g[h].is(f));)d[a].push(h),e=h<e?h:e;if(0===d[a].length)return c=!1,!0;d[a].sort(function(a,b){return a-b})}),!!c&&this.get_valid_rows(a,d,e)},h.can_go_widget_up=function(a){var b=a.row+a.size_y-1,c=!0,d=[],e=1e4;return this.for_each_column_occupied(a,function(f){var g=this.gridmap[f];d[f]=[];for(var h=b+1;--h>0&&(!this.is_widget(f,h)||this.is_player_in(f,h)||g[h].is(a.el));)this.is_player(f,h)||this.is_placeholder_in(f,h)||this.is_player_in(f,h)||d[f].push(h),h<e&&(e=h);if(0===d[f].length)return c=!1,!0;d[f].sort(function(a,b){return a-b})}),!!c&&this.get_valid_rows(a,d,e)},h.get_valid_rows=function(b,c,d){for(var e=b.row,f=b.row+b.size_y-1,g=b.size_y,h=d-1,i=[];++h<=f;){var j=!0;if(a.each(c,function(b,c){a.isArray(c)&&a.inArray(h,c)===-1&&(j=!1)}),j===!0&&(i.push(h),i.length===g))break}var k=!1;return 1===g?i[0]!==e&&(k=i[0]||!1):i[0]!==e&&(k=this.get_consecutive_numbers_index(i,g)),k},h.get_consecutive_numbers_index=function(a,b){for(var c=a.length,d=[],e=!0,f=-1,g=0;g<c;g++){if(e||a[g]===f+1){if(d.push(g),d.length===b)break;e=!1}else d=[],e=!0;f=a[g]}return d.length>=b&&a[d[0]]},h.get_widgets_overlapped=function(){var b=a([]),c=[],d=this.cells_occupied_by_player.rows.slice(0);return d.reverse(),a.each(this.cells_occupied_by_player.cols,a.proxy(function(e,f){a.each(d,a.proxy(function(d,e){if(!this.gridmap[f])return!0;var g=this.gridmap[f][e];this.is_occupied(f,e)&&!this.is_player(g)&&a.inArray(g,c)===-1&&(b=b.add(g),c.push(g))},this))},this)),b},h.on_start_overlapping_column=function(a){this.set_player(a,void 0,!1)},h.on_start_overlapping_row=function(a){this.set_player(void 0,a,!1)},h.on_stop_overlapping_column=function(a){var b=this;this.options.shift_larger_widgets_down&&this.for_each_widget_below(a,this.cells_occupied_by_player.rows[0],function(a,c){b.move_widget_up(this,b.player_grid_data.size_y)})},h.on_stop_overlapping_row=function(a){var b=this,c=this.cells_occupied_by_player.cols;if(this.options.shift_larger_widgets_down)for(var d=0,e=c.length;d<e;d++)this.for_each_widget_below(c[d],a,function(a,c){b.move_widget_up(this,b.player_grid_data.size_y)})},h.new_move_widget_to=function(a,b,c){var d=a.coords().grid;return this.remove_from_gridmap(d),d.row=c,d.col=b,this.add_to_gridmap(d),a.attr("data-row",c),a.attr("data-col",b),this.update_widget_position(d,a),this.$changed=this.$changed.add(a),this},h.move_widget=function(a,b,c,d){var e=a.coords().grid,f={col:b,row:c,size_x:e.size_x,size_y:e.size_y};return this.mutate_widget_in_gridmap(a,e,f),this.set_dom_grid_height(),this.set_dom_grid_width(),d&&d.call(this,f.col,f.row),a},h.move_widget_to=function(b,c){var d=this,e=b.coords().grid,f=this.widgets_below(b);return this.can_move_to(e,e.col,c)!==!1&&(this.remove_from_gridmap(e),e.row=c,this.add_to_gridmap(e),b.attr("data-row",c),this.$changed=this.$changed.add(b),f.each(function(b,c){var e=a(c),f=e.coords().grid,g=d.can_go_widget_up(f);g&&g!==f.row&&d.move_widget_to(e,g)}),this)},h.move_widget_up=function(b,c){if(void 0===c)return!1;var d=b.coords().grid,e=d.row,f=[];if(c||(c=1),!this.can_go_up(b))return!1;this.for_each_column_occupied(d,function(d){if(a.inArray(b,f)===-1){var g=b.coords().grid,h=e-c;if(!(h=this.can_go_up_to_row(g,d,h)))return!0;this.remove_from_gridmap(g),g.row=h,this.add_to_gridmap(g),b.attr("data-row",g.row),this.$changed=this.$changed.add(b),f.push(b)}})},h.move_widget_down=function(b,c){var d,e,f,g;if(c<=0)return!1;if(d=b.coords().grid,(e=d.row)+(b.coords().grid.size_y-1)+c>this.options.max_rows)return!1;if(f=[],g=c,!b)return!1;if(this.failed=!1,a.inArray(b,f)===-1){var h=b.coords().grid,i=e+c;if(this.widgets_below(b).each(a.proxy(function(b,c){if(this.failed!==!0){var d=a(c),e=d.coords().grid,f=this.displacement_diff(e,h,g);f>0&&(this.failed=this.move_widget_down(d,f)===!1)}},this)),this.failed)return!1;this.remove_from_gridmap(h),h.row=i,this.update_widget_position(h,b),b.attr("data-row",h.row),this.$changed=this.$changed.add(b),f.push(b)}return!0},h.can_go_up_to_row=function(b,c,d){var e,f=!0,g=[],h=b.row;if(this.for_each_column_occupied(b,function(a){for(g[a]=[],e=h;e--&&this.is_empty(a,e)&&!this.is_placeholder_in(a,e);)g[a].push(e);if(!g[a].length)return f=!1,!0}),!f)return!1;for(e=d,e=1;e<h;e++){for(var i=!0,j=0,k=g.length;j<k;j++)g[j]&&a.inArray(e,g[j])===-1&&(i=!1);if(i===!0){f=e;break}}return f},h.displacement_diff=function(a,b,c){var d=a.row,e=[],f=b.row+b.size_y;return this.for_each_column_occupied(a,function(a){for(var b=0,c=f;c<d;c++)this.is_empty(a,c)&&(b+=1);e.push(b)}),c-=Math.max.apply(Math,e),c>0?c:0},h.widgets_below=function(b){var c=a([]),e=a.isPlainObject(b)?b:b.coords().grid;if(void 0===e)return c;var f=this,g=e.row+e.size_y-1;return this.for_each_column_occupied(e,function(b){f.for_each_widget_below(b,g,function(b,d){if(!f.is_player(this)&&a.inArray(this,c)===-1)return c=c.add(this),!0})}),d.sort_by_row_asc(c)},h.set_cells_player_occupies=function(a,b){return this.remove_from_gridmap(this.placeholder_grid_data),this.placeholder_grid_data.col=a,this.placeholder_grid_data.row=b,this.add_to_gridmap(this.placeholder_grid_data,this.$player),this},h.empty_cells_player_occupies=function(){return this.remove_from_gridmap(this.placeholder_grid_data),this},h.can_go_down=function(b){var c=!0,d=this;return b.hasClass(this.options.static_class)&&(c=!1),this.widgets_below(b).each(function(){a(this).hasClass(d.options.static_class)&&(c=!1)}),c},h.can_go_up=function(a){var b=a.coords().grid,c=b.row,d=c-1,e=!0;return 1!==c&&(this.for_each_column_occupied(b,function(a){if(this.is_occupied(a,d)||this.is_player(a,d)||this.is_placeholder_in(a,d)||this.is_player_in(a,d))return e=!1,!0}),e)},h.can_move_to=function(a,b,c){var d=a.el,e={size_y:a.size_y,size_x:a.size_x,col:b,row:c},f=!0;if(this.options.max_cols!==1/0){if(b+a.size_x-1>this.cols)return!1}return!(this.options.max_rows<c+a.size_y-1)&&(this.for_each_cell_occupied(e,function(b,c){var e=this.is_widget(b,c);!e||a.el&&!e.is(d)||(f=!1)}),f)},h.get_targeted_columns=function(a){for(var b=(a||this.player_grid_data.col)+(this.player_grid_data.size_x-1),c=[],d=a;d<=b;d++)c.push(d);return c},h.get_targeted_rows=function(a){for(var b=(a||this.player_grid_data.row)+(this.player_grid_data.size_y-1),c=[],d=a;d<=b;d++)c.push(d);return c},h.get_cells_occupied=function(b){var c,d={cols:[],rows:[]};for(arguments[1]instanceof a&&(b=arguments[1].coords().grid),c=0;c<b.size_x;c++){var e=b.col+c;d.cols.push(e)}for(c=0;c<b.size_y;c++){var f=b.row+c;d.rows.push(f)}return d},h.for_each_cell_occupied=function(a,b){return this.for_each_column_occupied(a,function(c){this.for_each_row_occupied(a,function(a){b.call(this,c,a)})}),this},h.for_each_column_occupied=function(a,b){for(var c=0;c<a.size_x;c++){var d=a.col+c;b.call(this,d,a)}},h.for_each_row_occupied=function(a,b){for(var c=0;c<a.size_y;c++){var d=a.row+c;b.call(this,d,a)}},h.clean_up_changed=function(){var b=this;b.$changed.each(function(){b.options.shift_larger_widgets_down&&b.move_widget_up(a(this))})},h._traversing_widgets=function(b,c,d,e,f){var g=this.gridmap;if(g[d]){var h,i,j=b+"/"+c;if(arguments[2]instanceof a){var k=arguments[2].coords().grid;d=k.col,e=k.row,f=arguments[3]}var l=[],m=e,n={"for_each/above":function(){for(;m--&&!(m>0&&this.is_widget(d,m)&&a.inArray(g[d][m],l)===-1&&(h=f.call(g[d][m],d,m),l.push(g[d][m]),h)););},"for_each/below":function(){for(m=e+1,i=g[d].length;m<i;m++)this.is_widget(d,m)&&a.inArray(g[d][m],l)===-1&&(h=f.call(g[d][m],d,m),l.push(g[d][m]))}};n[j]&&n[j].call(this)}},h.for_each_widget_above=function(a,b,c){return this._traversing_widgets("for_each","above",a,b,c),this},h.for_each_widget_below=function(a,b,c){return this._traversing_widgets("for_each","below",a,b,c),this},h.get_highest_occupied_cell=function(){for(var a,b=this.gridmap,c=b[1].length,d=[],e=[],f=b.length-1;f>=1;f--)for(a=c-1;a>=1;a--)if(this.is_widget(f,a)){d.push(a),e.push(f);break}return{col:Math.max.apply(Math,e),row:Math.max.apply(Math,d)}},h.get_widgets_in_range=function(b,c,d,e){var f,g,h,i,j=a([]);for(f=d;f>=b;f--)for(g=e;g>=c;g--)(h=this.is_widget(f,g))!==!1&&(i=h.data("coords").grid,i.col>=b&&i.col<=d&&i.row>=c&&i.row<=e&&(j=j.add(h)));return j},h.get_widgets_at_cell=function(a,b){return this.get_widgets_in_range(a,b,a,b)},h.get_widgets_from=function(b,c){var d=a();return b&&(d=d.add(this.$widgets.filter(function(){var c=parseInt(a(this).attr("data-col"));return c===b||c>b}))),c&&(d=d.add(this.$widgets.filter(function(){var b=parseInt(a(this).attr("data-row"));return b===c||b>c}))),d},h.set_dom_grid_height=function(a){if(void 0===a){var b=this.get_highest_occupied_cell().row;a=(b+1)*this.options.widget_margins[1]+b*this.min_widget_height}return this.container_height=a,this.$el.css("height",this.container_height),this},h.set_dom_grid_width=function(a){void 0===a&&(a=this.get_highest_occupied_cell().col);var b=this.options.max_cols===1/0?this.options.max_cols:this.cols;return a=Math.min(b,Math.max(a,this.options.min_cols)),this.container_width=(a+1)*this.options.widget_margins[0]+a*this.min_widget_width,this.is_responsive()?(this.$el.css({"min-width":"100%","max-width":"100%"}),this):(this.$el.css("width",this.container_width),this)},h.is_responsive=function(){return this.options.autogenerate_stylesheet&&"auto"===this.options.widget_base_dimensions[0]&&this.options.max_cols!==1/0},h.get_responsive_col_width=function(){var a=this.cols||this.options.max_cols;return(this.$el[0].clientWidth-3-(a+1)*this.options.widget_margins[0])/a},h.resize_responsive_layout=function(){return this.min_widget_width=this.get_responsive_col_width(),this.generate_stylesheet(),this.update_widgets_dimensions(),this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0]),this},h.toggle_collapsed_grid=function(a,b){return a?(this.$widgets.css({"margin-top":b.widget_margins[0],"margin-bottom":b.widget_margins[0],"min-height":b.widget_base_dimensions[1]}),this.$el.addClass("collapsed"),this.resize_api&&this.disable_resize(),this.drag_api&&this.disable()):(this.$widgets.css({"margin-top":"auto","margin-bottom":"auto","min-height":"auto"}),this.$el.removeClass("collapsed"),this.resize_api&&this.enable_resize(),this.drag_api&&this.enable()),this},h.generate_stylesheet=function(b){var c,e="",f=this.is_responsive()&&this.options.responsive_breakpoint&&a(window).width()<this.options.responsive_breakpoint;b||(b={}),b.cols||(b.cols=this.cols),b.rows||(b.rows=this.rows),b.namespace||(b.namespace=this.options.namespace),b.widget_base_dimensions||(b.widget_base_dimensions=this.options.widget_base_dimensions),b.widget_margins||(b.widget_margins=this.options.widget_margins),this.is_responsive()&&(b.widget_base_dimensions=[this.get_responsive_col_width(),b.widget_base_dimensions[1]],this.toggle_collapsed_grid(f,b));var g=a.param(b);if(a.inArray(g,d.generated_stylesheets)>=0)return!1;for(this.generated_stylesheets.push(g),d.generated_stylesheets.push(g),c=1;c<=b.cols+1;c++)e+=b.namespace+' [data-col="'+c+'"] { left:'+(f?this.options.widget_margins[0]:c*b.widget_margins[0]+(c-1)*b.widget_base_dimensions[0])+"px; }\n";for(c=1;c<=b.rows+1;c++)e+=b.namespace+' [data-row="'+c+'"] { top:'+(c*b.widget_margins[1]+(c-1)*b.widget_base_dimensions[1])+"px; }\n";for(var h=1;h<=b.rows;h++)e+=b.namespace+' [data-sizey="'+h+'"] { height:'+(f?"auto":h*b.widget_base_dimensions[1]+(h-1)*b.widget_margins[1])+(f?"":"px")+"; }\n";for(var i=1;i<=b.cols;i++){var j=i*b.widget_base_dimensions[0]+(i-1)*b.widget_margins[0];e+=b.namespace+' [data-sizex="'+i+'"] { width:'+(f?this.$wrapper.width()-2*this.options.widget_margins[0]:j>this.$wrapper.width()?this.$wrapper.width():j)+"px; }\n"}return this.remove_style_tags(),this.add_style_tag(e)},h.add_style_tag=function(a){var b=document,c="gridster-stylesheet";if(""!==this.options.namespace&&(c=c+"-"+this.options.namespace),!document.getElementById(c)){var d=b.createElement("style");d.id=c,b.getElementsByTagName("head")[0].appendChild(d),d.setAttribute("type","text/css"),d.styleSheet?d.styleSheet.cssText=a:d.appendChild(document.createTextNode(a)),this.remove_style_tags(),this.$style_tags=this.$style_tags.add(d)}return this},h.remove_style_tags=function(){var b=d.generated_stylesheets,c=this.generated_stylesheets;this.$style_tags.remove(),d.generated_stylesheets=a.map(b,function(b){if(a.inArray(b,c)===-1)return b})},h.generate_faux_grid=function(a,b){this.faux_grid=[],this.gridmap=[];var c,d;for(c=b;c>0;c--)for(this.gridmap[c]=[],d=a;d>0;d--)this.add_faux_cell(d,c);return this},h.add_faux_cell=function(b,c){var d=a({left:this.baseX+(c-1)*this.min_widget_width,top:this.baseY+(b-1)*this.min_widget_height,width:this.min_widget_width,height:this.min_widget_height,col:c,row:b,original_col:c,original_row:b}).coords();return a.isArray(this.gridmap[c])||(this.gridmap[c]=[]),void 0===this.gridmap[c][b]&&(this.gridmap[c][b]=!1),this.faux_grid.push(d),this},h.add_faux_rows=function(a){a=window.parseInt(a,10);for(var b=this.rows,c=b+parseInt(a||1),d=c;d>b;d--)for(var e=this.cols;e>=1;e--)this.add_faux_cell(d,e);return this.rows=c,this.options.autogenerate_stylesheet&&this.generate_stylesheet(),this},h.add_faux_cols=function(a){a=window.parseInt(a,10);var b=this.cols,c=b+parseInt(a||1);c=Math.min(c,this.options.max_cols);for(var d=b+1;d<=c;d++)for(var e=this.rows;e>=1;e--)this.add_faux_cell(e,d);return this.cols=c,this.options.autogenerate_stylesheet&&this.generate_stylesheet(),this},h.recalculate_faux_grid=function(){var b=this.$wrapper.width();return this.baseX=(f.width()-b)/2,this.baseY=this.$wrapper.offset().top,"relative"===this.$wrapper.css("position")&&(this.baseX=this.baseY=0),a.each(this.faux_grid,a.proxy(function(a,b){this.faux_grid[a]=b.update({left:this.baseX+(b.data.col-1)*this.min_widget_width,top:this.baseY+(b.data.row-1)*this.min_widget_height})},this)),this.is_responsive()&&this.resize_responsive_layout(),this.options.center_widgets&&this.center_widgets(),this},h.resize_widget_dimensions=function(b){return b.widget_margins&&(this.options.widget_margins=b.widget_margins),b.widget_base_dimensions&&(this.options.widget_base_dimensions=b.widget_base_dimensions),this.min_widget_width=2*this.options.widget_margins[0]+this.options.widget_base_dimensions[0],this.min_widget_height=2*this.options.widget_margins[1]+this.options.widget_base_dimensions[1],this.$widgets.each(a.proxy(function(b,c){var d=a(c);this.resize_widget(d)},this)),this.generate_grid_and_stylesheet(),this.get_widgets_from_DOM(),this.set_dom_grid_height(),this.set_dom_grid_width(),this},h.get_widgets_from_DOM=function(){var b=this.$widgets.map(a.proxy(function(b,c){var d=a(c);return this.dom_to_coords(d)},this));return b=d.sort_by_row_and_col_asc(b),a(b).map(a.proxy(function(a,b){return this.register_widget(b)||null},this)).length&&this.$el.trigger("gridster:positionschanged"),this},h.get_num_widgets=function(){return this.$widgets.size()},h.set_num_columns=function(b){var c=this.options.max_cols,d=Math.floor(b/(this.min_widget_width+this.options.widget_margins[0]))+this.options.extra_cols,e=this.$widgets.map(function(){return a(this).attr("data-col")}).get();e.length||(e=[0]);var f=Math.max.apply(Math,e);this.cols=Math.max(f,d,this.options.min_cols),c!==1/0&&c>=f&&c<this.cols&&(this.cols=c),this.drag_api&&this.drag_api.set_limits(this.cols*this.min_widget_width+(this.cols+1)*this.options.widget_margins[0])},h.set_new_num_rows=function(b){var c=this.options.max_rows,d=this.$widgets.map(function(){return a(this).attr("data-row")}).get();d.length||(d=[0]);var e=Math.max.apply(Math,d);this.rows=Math.max(e,b,this.options.min_rows),c!==1/0&&(c<e||c<this.rows)&&(c=this.rows),this.min_rows=e,this.max_rows=c,this.options.max_rows=c;var f=this.rows*this.min_widget_height+(this.rows+1)*this.options.widget_margins[1];this.drag_api&&(this.drag_api.options.container_height=f),this.container_height=f,this.generate_faux_grid(this.rows,this.cols)},h.generate_grid_and_stylesheet=function(){var b=this.$wrapper.width();this.set_num_columns(b);var c=this.options.extra_rows;return this.$widgets.each(function(b,d){c+=+a(d).attr("data-sizey")}),this.rows=this.options.max_rows,this.baseX=(f.width()-b)/2,this.baseY=this.$wrapper.offset().top,this.options.autogenerate_stylesheet&&this.generate_stylesheet(),this.generate_faux_grid(this.rows,this.cols)},h.destroy=function(b){return this.$el.removeData("gridster"),a.each(this.$widgets,function(){a(this).removeData("coords")}),f.unbind(".gridster"),this.drag_api&&this.drag_api.destroy(),this.resize_api&&this.resize_api.destroy(),this.$widgets.each(function(b,c){a(c).coords().destroy()}),this.resize_api&&this.resize_api.destroy(),this.remove_style_tags(),b&&this.$el.remove(),this},a.fn.gridster=function(b){return this.each(function(){var c=a(this);c.data("gridster")||c.data("gridster",new d(this,b))})},d});
/**
 * Category Navi
 */
function Gws_Category_Navi(selector) {
  this.el = $(selector);
}

Gws_Category_Navi.prototype.setBaseUrl = function(url) {
  this.baseUrl = url;
};

Gws_Category_Navi.prototype.render = function(items, opts) {
  if (opts == null) {
    opts = {};
  }
  if (items.length == 0) {
    this.el.hide();
    return;
  }
  var _this = this;
  var list = [];
  var line = list[0];
  var last_depth = -1;
  var path = location.href.replace(/https?:\/\/.*?\//, '/');
  var isCate = null;
  var hideClose = opts["hideClose"];

  $.each(items, function(idx, item) {
    var depth = (item.name.match(/\//g) || []).length;
    var url = _this.baseUrl.replace('ID', item._id);

    if (depth == 0 || depth != last_depth) {
      list.push({ depth: depth, items: []});
      line = list[list.length - 1];
    }
    if (path.startsWith(url)) {
      isCate = item._id;
    }
    line.items.push('<a class="link-item" href="' + url + '">' + item.trailing_name + '</a>');
    last_depth = depth;
  });

  var html = [];
  $.each(list, function(idx, data) {
    html.push('<div class="depth depth-' + data.depth + '">');
    html.push(data.items.join('<span class="separator"></span>'));
    html.push('</div>');
  });
  this.el.find('.dropdown-menu').append(html.join(''));

  var toggle = this.el.find('.dropdown-toggle');
  if (!hideClose && isCate) {
    var icon = '<i class="material-icons md-18 md-dark">&#xE14C;</i>';
    toggle.after('<a class="ml-1" href="' + toggle.attr('href') + '">' + icon + '</a>');
  }
  toggle.on("click", function() {
    return false;
  });
};
// Tab
function Gws_Tab() {
}

Gws_Tab.renderTabs = function(selector) {
  var path = location.pathname + "/";
  $(selector).find('a').each(function() {
    var $menu = $(this);
    if (path.match(new RegExp('^' + $menu.attr('href') + '(\/|$)'))) {
      $menu.addClass("current")
    }
  });
};
this.Gws_Popup = (function () {
  function Gws_Popup() {
  }

  Gws_Popup.init = null;

  Gws_Popup.render = function (target, content) {
    var popup;
    if (!this.init) {
      this.init = true;
      $(window).resize(function () {
        return $('.gws-popup').remove();
      });
      $(document).on("click", function (ev) {
        if (!$(ev.target).closest('.gws-popup, .gws-popup-event').length) {
          return $('.gws-popup').remove();
        }
      });
    }
    $('.gws-popup').remove();
    popup = $("<div class='gws-popup'></div>").html($(content));
    $("body").append(popup);
    target.addClass('gws-popup-event');
    return this.renderPopup(target);

  };
  //$(window).resize(@render Popup)

  Gws_Popup.renderPopup = function (target) {
    var popup, pos_left, pos_top;
    popup = $('.gws-popup');
    if ($(window).width() < popup.outerWidth() * 1.5) {
      popup.css('max-width', $(window).width() / 2);
    } else {

    }
    //pop up.css(max'width',340 );
    pos_left = target.offset().left + (target.outerWidth() / 2) - (popup.outerWidth() / 2);
    pos_top = target.offset().top - popup.outerHeight() - 20;
    if (pos_left < 0) {
      pos_left = target.offset().left + target.outerWidth() / 2 - 20;
      popup.addClass('left');
    } else {
      popup.removeClass('left');
    }
    if (pos_left + popup.outerWidth() > $(window).width()) {
      pos_left = target.offset().left - popup.outerWidth() + target.outerWidth() / 2 + 20;
      popup.addClass('right');
    } else {
      popup.removeClass('right');
    }
    if (pos_top < 0) {
      pos_top = target.offset().top + target.outerHeight();
      popup.addClass('top');
    } else {
      popup.removeClass('top');
    }
    return popup.css({
      left: pos_left,
      top: pos_top
    }).animate({
      top: '+=10',
      opacity: 1
    }, 50);
  };

  return Gws_Popup;

})();
this.Gws_Member = (function () {
  function Gws_Member() {
  }

  Gws_Member.groups = null;

  Gws_Member.users = null;

  Gws_Member.render = function () {
    if ($('.js-copy-groups').length < 2) {
      $('.js-copy-groups').remove();
      $('.js-paste-groups').remove();
    }
    $('.js-copy-groups').on("click", function () {
      return Gws_Member.copyGroups($(this));
    });
    $('.js-paste-groups').on("click", function () {
      return Gws_Member.pasteGroups($(this));
    });
    if ($('.js-copy-users').length < 2) {
      $('.js-copy-users').remove();
      $('.js-paste-users').remove();
    }
    $('.js-copy-users').on("click", function () {
      return Gws_Member.copyUsers($(this));
    });
    return $('.js-paste-users').on("click", function () {
      return Gws_Member.pasteUsers($(this));
    });
  };

  Gws_Member.confirmReadableSetting = function () {
    return $('.save').on('click', function () {
//$(submit).trigger("click")
      if ($('.gws-addon-readable-setting tbody tr').length === 0) {
        return confirm(i18next.t("gws.confirm.readable_setting.empty"));
      }
    });
  };

  Gws_Member.copyGroups = function (el) {
    this.groups = el.closest('dl').find('tbody tr').clone(true);
    this.showLog(el, this.groups.length + i18next.t('gws.member_log.copy_groups'));
    return false;
  };

  Gws_Member.pasteGroups = function (el) {
    var num;
    num = this.pasteItems(el, this.groups);
    this.showLog(el, num + i18next.t('gws.member_log.paste_groups'));
    return false;
  };

  Gws_Member.copyUsers = function (el) {
    this.users = el.closest('dl').find('tbody tr').clone(true);
    this.showLog(el, this.users.length + i18next.t('gws.member_log.copy_users'));
    return false;
  };

  Gws_Member.pasteUsers = function (el) {
    var num;
    num = this.pasteItems(el, this.users);
    this.showLog(el, num + i18next.t('gws.member_log.paste_users'));
    return false;
  };

  Gws_Member.pasteItems = function (el, list) {
    var dl, name, num, tbody;
    if (!list || list.length === 0) {
      return 0;
    }
    dl = el.closest('dl');
    dl.find('table').show();
    tbody = dl.find('tbody');
    name = dl.find('.hidden-ids').attr('name');
    num = 0;
    list.each(function () {
      var tr;
      if (tbody.find('tr[data-id="' + $(this).data('id') + '"]').length === 0) {
        tr = $(this).clone(true);
        tr.find('input').attr('name', name);
        tbody.append(tr);
        return num += 1;
      }
    });
    return num;
  };

  Gws_Member.showLog = function (el, msg) {
    $(".gws-member-log").remove();
    return $("<span class='gws-member-log'>" + msg + "</span>").appendTo(el.parent()).hide().fadeIn(200);
  };

  return Gws_Member;

})();
this.Gws_Reminder = (function () {
  function Gws_Reminder() {
  }

  Gws_Reminder.renderList = function (opts) {
    var el;
    if (opts == null) {
      opts = {};
    }
    el = $(opts['el'] || document);
    el.find('.list-item').each(function () {
      var $a = $('<a />', { class: "restore", href: "#", style: "display: none;" })
        .text(i18next.t("gws/reminder.links.restore_reminder"));
      return $(this).find('.links').prepend($a);
    });
    el.find('.list-item.deleted').each(function () {
      $(this).find('.check, .meta, .delete, .updated, .more-btn').hide();
      $(this).find('.dropdown-menu').removeClass('active');
      $(this).find('.restore').show();
      return $(this).find('.notification').hide();
    });
    el.find('.list-item .delete').on("click", function () {
      var item;
      item = $(this).closest('.list-item');
      $.ajax({
        url: opts['url'],
        method: 'post',
        data: {
          _method: 'delete',
          id: item.data('id'),
          item_id: item.data('item_id'),
          item_model: item.data('model'),
          item_name: item.data('name'),
          date: item.data('date')
        },
        success: function (data) {
          item.toggleClass('gws-list-item--deleted').find('.check, .meta, .delete, .updated, .more-btn').hide();
          item.find('.dropdown-menu').removeClass('active');
          item.find('.restore').show();
          item.find('.notification').hide();
          return false;
        },
        error: function (data) {
          return alert('Error');
        }
      });
      return false;
    });
    return el.find('.list-item .restore').on("click", function () {
      var item;
      item = $(this).closest('.list-item');
      $.ajax({
        url: opts['restore_url'],
        method: 'post',
        data: {
          id: item.data('id'),
          item_id: item.data('item_id'),
          item_model: item.data('model'),
          item_name: item.data('name'),
          date: item.data('date')
        },
        success: function (data) {
          item.toggleClass('gws-list-item--deleted').find('.check, .meta, .delete, .more-btn').show();
          item.find('.restore').hide();
          if (item.find('.notification')[0]) {
            item.find('.notification')[0].selectedIndex = 0;
          }
          item.find('.notification').show();
          return false;
        },
        error: function (data) {
          return alert('Error');
        }
      });
      return false;
    });
  };

  return Gws_Reminder;

})();
function Gws_Bookmark(el, defaultName) {
  this.$el = $(el);
  this.$form = this.$el.find("form");
  this.defaultName = defaultName;
  this.loading = false;
}

Gws_Bookmark.prototype.renderCreate = function() {
  var self = this;

  self.$el.on("click", function() {
    if (self.loading) {
      return false;
    }
    self.loading = true;
    self.$form.ajaxForm({
      type: "post",
      data: {
        default_name: self.defaultName,
      },
      dataType: 'html',
      beforeSend: function() {
        self.$form.find(".dropdown-menu").html(SS.loading);
      },
      success: function(html) {
        self.$el.replaceWith(html);
      },
      error: function(_xhr, _status, _error) {
        alert('Error');
      }
    });
    self.$form.submit();
    return false;
  });
};

Gws_Bookmark.prototype.renderUpdate = function() {
  var self = this;

  self.$el.on("click", function() {
    $(this).find(".dropdown-menu").addClass("active");
    return false;
  });

  self.$el.find("input").on('keypress', function (ev) {
    if ((ev.which && ev.which === SS.KEY_ENTER) || (ev.keyCode && ev.keyCode === SS.KEY_ENTER)) {
      return false;
    } else {
      return true;
    }
  });

  // click update button
  self.$form.find("button.update").on("click", function() {
    if (self.loading) {
      return false;
    }
    self.loading = true;

    self.$form.ajaxForm({
      type: "post",
      dataType: 'html',
      data: {
        default_name: self.defaultName,
      },
      beforeSend: function() {
        self.$form.find(".dropdown-menu").html(SS.loading);
      },
      success: function(html) {
        self.$el.replaceWith(html);
      },
      error: function(_xhr, _status, _error) {
        alert('Error');
      }
    });
    self.$form.submit();
    return false;
  });

  // click delete button
  self.$form.find("button.delete").on("click", function() {
    if (self.loading) {
      return false;
    }
    self.loading = true;

    self.$form.ajaxForm({
      type: "delete",
      dataType: 'html',
      data: {
        default_name: self.defaultName,
      },
      beforeSend: function() {
        self.$form.find(".dropdown-menu").html(SS.loading);
      },
      success: function(html) {
        self.$el.replaceWith(html);
      },
      error: function(_xhr, _status, _error) {
        alert('Error');
      }
    });
    self.$form.submit();
    return false;
  });
};
// Readable Setting UI
function Gws_ReadableSetting(selector) {
  this.el = $(selector);
}

Gws_ReadableSetting.prototype.render = function() {
  var _this = this;
  this.el.find('.buttons input').on("change", function() {
    var val = $(this).val();
    if (val == 'select') {
      _this.showSelectForm();
    } else {
      _this.hideSelectForm();
    }
  });

  var val = this.el.find('.buttons input:checked').val();
  if (val == 'select') {
    this.el.find('.gws-addon-readable-setting-select').show();
  } else {
    this.el.find('.gws-addon-readable-setting-select').hide();
  }
};

Gws_ReadableSetting.prototype.showSelectForm = function() {
  this.el.find('.gws-addon-readable-setting-select').slideDown("fast");
}

Gws_ReadableSetting.prototype.hideSelectForm = function() {
  this.el.find('.gws-addon-readable-setting-select').slideUp("fast");
};
function Gws_Contrast(opts) {
  this.opts = opts;
  this.$el = $('#user-contrast-menu');
  this.template = 'body * { color: :color !important; border-color: :color !important; background: :background !important; } ' +
                  'body *:after { background: :background !important; }';

  this.render();
}

Gws_Contrast.getContrastId = function(siteId) {
  return Cookies.get("gws-contrast-" + siteId);
};

Gws_Contrast.setContrastId = function(siteId, contrastId) {
  Cookies.set("gws-contrast-" + siteId, contrastId, { expires: 7, path: '/' });
};

Gws_Contrast.removeContrastId = function(siteId) {
  Cookies.remove("gws-contrast-" + siteId);
};

Gws_Contrast.prototype.render = function() {
  var _this = this;

  this.$el.data('load', function() {
    _this.loadContrasts();
  });

  this.$el.on('click', '.gws-contrast-item', function(ev) {
    var $this = $(this);
    var id = $this.data('id');
    if (id === 'default') {
      _this.removeContrast($this.data('text-color'), $this.data('color'));
      Gws_Contrast.removeContrastId(_this.opts.siteId);
    } else {
      _this.changeContrast($this.data('text-color'), $this.data('color'));
      Gws_Contrast.setContrastId(_this.opts.siteId, id);
    }
    SS.notice(_this.opts.notice.replace(':name', $this.text()));

    ev.stopPropagation();
  });
};

Gws_Contrast.prototype.loadContrasts = function() {
  if (this.$el.data('loadedAt')) {
    this.checkActiveContrast();
    return;
  }

  var _this = this;
  $.ajax({
    url: this.opts.url,
    type: 'GET',
    dataType: 'json',
    success: function(data) { _this.renderContrasts(data); },
    error: function(xhr, status, error) { _this.showMessage(this.opts.loadError); },
    complete: function(xhr, status) { _this.completeLoading(xhr); }
  });
};

Gws_Contrast.prototype.completeLoading = function(xhr) {
  this.$el.data('loadedAt', Date.now());
  this.$el.find('.gws-contrast-loading').closest('li').hide();
};

Gws_Contrast.prototype.showMessage = function(message) {
  this.$el.append($('<li/>').html($('<div class="gws-contrast-error"/>').text(message)));
};

Gws_Contrast.prototype.renderContrasts = function(data) {
  if (data.length === 0) {
    this.showMessage(this.opts.noContrasts);
    return;
  }

  this.renderContrast('default', this.opts.defaultContrast);

  var _this = this;
  $.each(data, function() {
    _this.renderContrast(this._id['$oid'], this.name, this.color, this.text_color);
  });

  this.checkActiveContrast();
};

Gws_Contrast.prototype.renderContrast = function(id, name, color, textColor) {
  var dataAttrs = { id: id };
  if (color) {
    dataAttrs.color = color;
  }
  if (textColor) {
    dataAttrs.textColor = textColor;
  }

  var $input = $('<input/>', { type: 'radio', name: 'gws-contrast-item', value: id });
  var $label = $('<label/>', { class: 'gws-contrast-item', data: dataAttrs });
  $label.append($input);
  $label.append($('<span class="gws-contrast-name"/>').text(name));

  this.$el.append($('<li/>').append($label));
};

Gws_Contrast.prototype.checkActiveContrast = function() {
  var contrastId = Gws_Contrast.getContrastId(this.opts.siteId);
  if (! contrastId) {
    $('input[name="gws-contrast-item"]').val(['default']);
    return;
  }

  $('input[name="gws-contrast-item"]').val([contrastId]);
};

Gws_Contrast.prototype.changeContrast = function(textColor, color) {
  if (! this.$style) {
    this.$style = $('<style/>', { type: 'text/css' });
    $('head').append(this.$style);
  }

  this.$style.html(this.template.replace(/:color/g, textColor).replace(/:background/g, color));
};

Gws_Contrast.prototype.removeContrast = function() {
  if (! this.$style) {
    return;
  }

  this.$style.html('');
};
function Gws_Workload_Navi(selector) {
  this.el = $(selector);
}

Gws_Workload_Navi.prototype.setBaseUrl = function(url) {
  this.baseUrl = url;
};

Gws_Workload_Navi.prototype.render = function(items) {
  if (items.length == 0) {
    this.el.hide();
    return;
  }
  var _this = this;
  var list = [];

  $.each(items, function(idx, item) {
    var url = _this.baseUrl.replace('ID', item._id);
    list.push('<a class="link-item" href="' + url + '" data-id="' + item._id + '">' + item.name + '</a>');
  });

  var html = [];
  $.each(list, function(idx, data) {
    html.push(data);
  });
  this.el.find('.dropdown-menu').append(html.join(''));

  var toggle = this.el.find('.dropdown-toggle');
  toggle.on("click", function() {
    return false;
  });
};
function Gws_SearchForm(el) {
  this.$el = $(el);
  this.render();
}

Gws_SearchForm.render = function() {
  $(document).find(".gws-search").each(function() {
    new Gws_SearchForm(this)
  });
};

Gws_SearchForm.prototype.render = function() {
  var self = this;

  self.$el.find('[name="target"]').on("change", function(){
    var target = $(this).val();
    self.toggleTarget(target);
  });

  var target = Cookies.get("ss-gws-search");
  if (!target || !self.$el.find('[data-target="' + target + '"]').length) {
    target = self.$el.find('[data-target]:first').attr("data-target");
    Cookies.set("ss-gws-search", target, {
      expires: 7,
      path: '/'
    });
  }
  self.$el.find('[name="target"][value="' + target + '"]').prop("checked", true);
  self.toggleTarget(target);
};

Gws_SearchForm.prototype.toggleTarget = function(target) {
  var self = this;

  var keyword = self.$el.find(".keyword:visible").val();
  self.$el.find(".keyword").val(keyword);

  self.$el.find('[data-target]').hide();
  self.$el.find('[data-target="' + target + '"]').show();

  Cookies.set("ss-gws-search", target, {
    expires: 7,
    path: '/'
  });
}

Gws_SearchForm.renderExternalSearch = function() {
  $("a[data-external-search-url]").on("click", function() {
    var href = $(this).attr("data-external-search-url");
    var keyword = $('.list-head-search-full [name="s[keyword]"]').val();
    href = href.replace('KEYWORD', keyword);
    $(this).attr("href", href);
    return true;
  });

  // Search for KEYWORD using ...
  var showKeyword = function() {
    var keyword = $('.list-head-search-full [name="s[keyword]"]').val();
    $(".external-search .search-for-keyword").each(function(){
      if (keyword) {
        $(this).find(".with-keyword").show();
        $(this).find(".default").hide();

        $(this).find(".with-keyword .keyword").text(keyword);
      } else {
        $(this).find(".with-keyword").hide();
        $(this).find(".default").show();
      }
    });
  }
  $('.list-head-search-full [name="s[keyword]"]').on("keyup", showKeyword);
  showKeyword();
};
this.Gws_Schedule_Plan = (function () {
  var convertToTime = function(date, templateTime) {
    if (templateTime) {
      return date.millisecond(templateTime.millisecond())
        .second(templateTime.second())
        .minute(templateTime.minute())
        .hour(templateTime.hour());
    } else {
      return date.millisecond(0).second(0).minute(0).hour(9);
    }
  }

  function Gws_Schedule_Plan(el) {
    this.$el = $(el);

    this.$datetimeStartEl = this.$el.find(".datetime.start");
    this.$datetimeEndEl = this.$el.find(".datetime.end");
    this.$dateStartEl = this.$el.find(".date.start");
    this.$dateEndEl = this.$el.find(".date.end");
    this.$allday = this.$el.find('#item_allday');

    this.context = {
      startAt: SS_DateTimePicker.momentValue(this.$datetimeStartEl) || SS_DateTimePicker.momentValue(this.$dateStartEl),
      endAt: SS_DateTimePicker.momentValue(this.$datetimeEndEl) || SS_DateTimePicker.momentValue(this.$dateEndEl)
    }
    this.context.difference = SS_StartEndSynchronizer.calcDifference(this.context.startAt, this.context.endAt);
    // console.log({ startAt: this.context.startAt.format(), endAt: this.context.endAt.format(), difference: this.context.difference });

    this.render();
  }

  Gws_Schedule_Plan.renderForm = function () {
    $(".gws-schedule-start-end-combo").each(function() { new Gws_Schedule_Plan(this) });
  };

  Gws_Schedule_Plan.prototype.isAllDay = function() {
    return this.$allday.prop('checked');
  };

  Gws_Schedule_Plan.prototype.render = function() {
    var self = this;

    self.$datetimeStartEl.on("ss:changeDateTime", function() {
      self.context.startAt = SS_DateTimePicker.momentValue(self.$datetimeStartEl);
      if (self.context.startAt) {
        self.context.endAt = moment(self.context.startAt).add(self.context.difference, "milliseconds");
      }
      // update $datetimeEndEl, $dateStartEl, $dateEndEl
      SS_DateTimePicker.momentValue(self.$datetimeEndEl, self.context.endAt);
      SS_DateTimePicker.momentValue(self.$dateStartEl, self.context.startAt);
      SS_DateTimePicker.momentValue(self.$dateEndEl, self.context.endAt);
    });
    self.$datetimeEndEl.on("ss:changeDateTime", function() {
      self.context.endAt = SS_DateTimePicker.momentValue(self.$datetimeEndEl);
      if (self.context.endAt) {
        self.context.difference = SS_StartEndSynchronizer.calcDifference(self.context.startAt, self.context.endAt);
      }
      // update $dateEndEl
      SS_DateTimePicker.momentValue(self.$dateEndEl, self.context.endAt);
    });
    self.$dateStartEl.on("ss:changeDateTime", function() {
      var startDate = SS_DateTimePicker.momentValue(self.$dateStartEl);
      if (startDate) {
        self.context.startAt = convertToTime(startDate, self.context.startAt);
        self.context.endAt = moment(self.context.startAt).add(self.context.difference, "milliseconds");
      } else {
        self.context.startAt = null;
      }
      // update $datetimeStartEl, $datetimeEndEl, $dateEndEl
      SS_DateTimePicker.momentValue(self.$datetimeStartEl, self.context.startAt);
      SS_DateTimePicker.momentValue(self.$datetimeEndEl, self.context.endAt);
      SS_DateTimePicker.momentValue(self.$dateEndEl, self.context.endAt);
    });
    self.$dateEndEl.on("ss:changeDateTime", function() {
      var endDate = SS_DateTimePicker.momentValue(self.$dateEndEl);
      if (endDate) {
        self.context.endAt = convertToTime(endDate, self.context.endAt);
        self.context.difference = SS_StartEndSynchronizer.calcDifference(self.context.startAt, self.context.endAt);
      } else {
        self.context.endAt = null;
      }
      // update $datetimeEndEl
      SS_DateTimePicker.momentValue(self.$datetimeEndEl, self.context.endAt);
    });

    self.$allday.on("change", function () {
      self.changeDateForm();
    });
    self.changeDateForm();
    self.$el.trigger("ss:initialized");
  };

  Gws_Schedule_Plan.prototype.changeDateForm = function () {
    if (this.isAllDay()) {
      this.$el.find('.dates-field').removeClass("hide");
      this.$el.find('.datetimes-field').addClass("hide");
    } else {
      this.$el.find('.dates-field').addClass("hide");
      this.$el.find('.datetimes-field').removeClass("hide");
    }
  };

  return Gws_Schedule_Plan;

})();
this.Gws_Schedule_Repeat_Plan = (function () {
  function Gws_Schedule_Repeat_Plan() {
  }

  Gws_Schedule_Repeat_Plan.renderForm = function () {
    this.changeRepeatForm();
    this.relateDateForm();
    return $('#item_repeat_type').on("change", function () {
      return Gws_Schedule_Repeat_Plan.changeRepeatForm();
    });
  };

  Gws_Schedule_Repeat_Plan.changeRepeatForm = function () {
    var repeatType = $('#item_repeat_type').val();
    if (!repeatType) {
      $('.gws-schedule-repeat').addClass("hide");
      return;
    }

    $('.gws-schedule-repeat').removeClass("hide");
    $(".repeat-daily, .repeat-weekly, .repeat-monthly").hide();
    $(".repeat-" + repeatType).show();
  };

  Gws_Schedule_Repeat_Plan.relateDateForm = function () {
    new SS_StartEndSynchronizer('.date.repeat_start', '.date.repeat_end');
  };

  Gws_Schedule_Repeat_Plan.renderSubmitButtons = function () {
    var b1, b2, b3, buttons, form, sp;
    form = $("#main form");
    sp = '<span class="gws-schedule-btn-space"></span>';
    b1 = $('<input />', { type: "button", class: "btn", value: i18next.t("gws/schedule.buttons.delete_one") });
    b2 = $('<input />', { type: "button", class: "btn", value: i18next.t("gws/schedule.buttons.delete_later") });
    b3 = $('<input />', { type: "button", class: "btn", value: i18next.t("gws/schedule.buttons.delete_all") });
    b1.on('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="one" />').submit();
    });
    b2.on('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="later" />').submit();
    });
    b3.on('click', function () {
      return form.append('<input type="hidden" name="item[edit_range]" value="all" />').submit();
    });
    buttons = $('<div class="gws-schedule-repeat-submit"></div>');
    buttons.append(b1).append(sp).append(b2).append(sp).append(b3);
    return $('.send .save, .send .delete').on("click", function () {
      if ($("#item_repeat_type").val() !== "") {
        $.colorbox({
          inline: true,
          href: buttons
        });
        return false;
      }
    });
  };

  return Gws_Schedule_Repeat_Plan;

})();
function Gws_Schedule_Integration() {
}

Gws_Schedule_Integration.paths = {};

Gws_Schedule_Integration.render = function() {
  var $el = $(".gws-schedule-box");
  if (! $el[0]) {
    return;
  }

  $el.find(".send-message").each(function() {
    $(this).on("click", function(ev) {
      var userId = $(this).closest("[data-user-id]").data("user-id");
      location.href = Gws_Schedule_Integration.paths.newMemoMessage + "?to%5B%5D=" + userId;
    });
  });

  $el.find(".send-email").each(function() {
    $(this).on("click", function(ev) {
      var email = $(this).closest("[data-email]").data("email");
      location.href = Gws_Schedule_Integration.paths.newWebmail + "?item%5Bto%5D=" + encodeURIComponent(email);
    });
  });

  $el.find(".copy-email-address").each(function() {
    $(this).on("click", function(ev) {
      $(this).closest("[data-email]").find(".clipboard-copy-button").trigger("click");

      $(".dropdown, .dropdown-menu").removeClass('active');

      ev.preventDefault();
      return false;
    });
  });
};
this.Gws_Schedule_Todo_Search = (function () {
  function Gws_Schedule_Todo_Search(el) {
    this.$el = $(el);
    this.templateHtml = this.$el.find("#schedule-todo-selected-member-template").html();

    this.render();
  }

  Gws_Schedule_Todo_Search.prototype.render = function() {
    var self = this;

    this.$el.find("select.schedule-todo-auto-submit").on("change", function() {
      self.scheduleToSubmit();
    });

    var $btn = this.$el.find(".schedule-todo-member-select-btn");
    if ($btn[0]) {
      var href = $btn.data("href");
      $btn.colorbox({ href: href, width: "90%", height: "90%" });

      $btn.data("on-select", function ($item) {
        var $x = $item.closest("[data-id]");
        if ($x.length === 0) {
          return;
        }

        self.selectUser($x.data());
      });

      this.$el.on("click", ".schedule-todo-selected-member .dismiss", function () {
        $(this).closest(".schedule-todo-selected-member").remove();
        self.scheduleToSubmit();
      });
    }
  };

  Gws_Schedule_Todo_Search.prototype.selectUser = function(userData) {
    var id = userData.id;
    var name = userData.longName;

    if (this.$el.find(".schedule-todo-selected-member[data-id=" + id + "]").length > 0) {
      return;
    }

    var html = this.templateHtml.replace(/#id/g, id).replace(/#name/g, name);
    this.$el.find(".schedule-todo-selected-members").append(html).removeClass("hide");
    this.scheduleToSubmit();
  };

  Gws_Schedule_Todo_Search.prototype.scheduleToSubmit = function() {
    if (this.timerId) {
      return;
    }

    var self = this;
    this.timerId = setTimeout(function() { self.$el.submit(); }, 0);
  };

  return Gws_Schedule_Todo_Search;

})();
this.Gws_Schedule_Todo_Index = (function () {
  function Gws_Schedule_Todo_Index(el) {
    this.$el = $(el);
    this.render();
  }

  var showEl = function($el) {
    $el.removeClass("hide");
  };

  var hideEl = function($el) {
    $el.addClass("hide");
  };

  var isExpanded = function($listItemHeader) {
    var status = $listItemHeader.find(".list-item-switch").html();
    return status === "expand_less";
  };

  Gws_Schedule_Todo_Index.prototype.render = function() {
    var self = this;

    this.$el.find(".gws-schedule-todo-list-item-header").on("click", function() {
      self.toggleListItems($(this));
    });
  };

  Gws_Schedule_Todo_Index.prototype.toggleListItems = function($listItemHeader) {
    if (isExpanded($listItemHeader)) {
      this.collapseListItems($listItemHeader);
    } else {
      this.expandListItems($listItemHeader);
    }
  };

  Gws_Schedule_Todo_Index.prototype.collapseListItems = function($listItemHeader) {
    $listItemHeader.find(".list-item-switch").html("expand_more");
    this.eachListItem($listItemHeader, function() {
      hideEl($(this));
    });
  };

  Gws_Schedule_Todo_Index.prototype.expandListItems = function($listItemHeader) {
    $listItemHeader.find(".list-item-switch").html("expand_less");

    var self = this;
    this.eachListItem($listItemHeader, function() {
      var $this = $(this);
      if (self.examineToShow($this)) {
        showEl($(this));
      }
    });
  };

  Gws_Schedule_Todo_Index.prototype.examineToShow = function($listItem) {
    if ($listItem.hasClass("gws-schedule-todo-list-item-header")) {
      var parentGroup = $listItem.data("parent");
      if (parentGroup) {
        return this.examineToShow(this.$el.find("#" + parentGroup));
      }

      return true;
    }

    var listItemGroup = $listItem.data("group");
    var $listItemHeader = this.$el.find("#" + listItemGroup);
    if (!isExpanded($listItemHeader)) {
      return false;
    }

    var parentGroup = $listItemHeader.data("parent");
    if (parentGroup) {
      return this.examineToShow(this.$el.find("#" + parentGroup));
    }

    return true;
  };

  Gws_Schedule_Todo_Index.prototype.eachListItem = function($listItemHeader, callback) {
    var targetGroup = $listItemHeader.data("group");
    var targetDepth = $listItemHeader.data("depth");

    $.each($listItemHeader.nextAll(".list-item"), function() {
      var $this = $(this);
      var group = $this.data("group");
      var depth = $this.data("depth");
      if (group !== targetGroup && depth <= targetDepth) {
        return false;
      }

      callback.apply(this);
    });
  };

  return Gws_Schedule_Todo_Index;

})();
function Gws_Schedule_Csv(el) {
  this.$el = $(el);
  this.$importMode = this.$el.find('#import_mode');
  this.$importLog = this.$el.find('.import-log');
}

Gws_Schedule_Csv.render = function (el) {
  var instance = new Gws_Schedule_Csv(el);
  instance.render();
  return instance;
};

Gws_Schedule_Csv.prototype.render = function () {
  var self = this;
  this.$el.find('.import-confirm').on("click", function(){
    self.$importMode.val('confirm');
  });
  this.$el.find('.import-save').on("click", function(){
    self.$importMode.val('save');
  });
  this.$el.find('#import_form').ajaxForm({
    beforeSubmit: function() {
      self.$importLog.html($('<span />', { class: "import-loading" }).text(i18next.t("ss.notice.uploading")));
      SS_AddonTabs.show('#import-result');
    },
    success: function(data, status) {
      self.renderResult(data);
    },
    error: function(xhr, status, error) {
      self.renderError(xhr, status, error);
    }
  });
//  this.$el.find('.download-csv-template').on("click", function() {
//    setTimeout(function() { self.showCsvDescription(); }, 0);
//    return true;
//  });
  this.$el.find('.show-csv-description').on("click", function() {
    self.showCsvDescription();
  });
}

Gws_Schedule_Csv.prototype.renderResult = function(data) {
  var log = this.$importLog;
  log.html('')

  if (data.messages) {
    log.append('<div class="mb-1">' + data.messages.join('<br />') + '</div>');
  }
  if (data.items) {
    var count = { exist: 0, entry: 0, saved: 0, error: 0 };
    var template = '\
      <table class="index mt-1"><thead><tr> \
        <th style="width: 150px"><%= start_at %></th> \
        <th style="width: 150px"><%= end_at %></th> \
        <th style="width: 30%"><%= name %></th> \
        <th><%= result %></th> \
      </tr></thead><tbody>';
    var html = ejs.render(
      template,
      {
        start_at: i18next.t("mongoid.attributes.gws/schedule/planable.start_at"),
        end_at: i18next.t("mongoid.attributes.gws/schedule/planable.end_at"),
        name: i18next.t("mongoid.attributes.gws/schedule/planable.name"),
        result: i18next.t('gws/schedule.import.result')
      });

    $.each(data.items, function(i, item){
      if (item.result == 'exist') count.exist += 1;
      if (item.result == 'entry') count.entry += 1;
      if (item.result == 'saved') count.saved += 1;
      if (item.result == 'error') count.error += 1;

      html += '<tr class="import-' + item.result + '">' +
        '<td>' + SS.formatTime(item.start_at) + '</td>' +
        '<td>' + SS.formatTime(item.end_at) + '</td>' +
        '<td>' + item.name + '</td>' +
        '<td>' + item.messages.join('<br />') + '</td>' +
        '</tr>'
    });
    html += '</tbody></table>';

    var tabs = '<div class="mb-1">';
    if (count.exist) tabs += ejs.render('<span class="ml-2 import-exist"><%= text %>(<%= count.exist %>)</span>', { text: i18next.t('gws/schedule.import.exist'), count: count });
    if (count.entry) tabs += ejs.render('<span class="ml-2 import-entry"><%= text %>(<%= count.entry %>)</span>', { text: i18next.t('gws/schedule.import.entry'), count: count });
    if (count.saved) tabs += ejs.render('<span class="ml-2 import-saved"><%= text %>(<%= count.saved %>)</span>', { text: i18next.t('gws/schedule.import.saved'), count: count });
    if (count.error) tabs += ejs.render('<span class="ml-2 import-error"><%= text %>(<%= count.error %>)</span>', { text: i18next.t('gws/schedule.import.error'), count: count });
    tabs += '</div>'

    log.append(tabs + html);
  }
}

Gws_Schedule_Csv.prototype.renderError = function(xhr, status, error) {
  try {
    var errors = xhr.responseJSON;
    var msg = errors.join("\n");
    this.$importLog.html(msg);
  } catch (ex) {
    this.$importLog.html("Error: " + error);
  }
};

Gws_Schedule_Csv.prototype.showCsvDescription = function() {
  var href = this.$el.find('.show-csv-description').attr("href");
  $.colorbox({
    inline: true, href: href, width: "90%", height: "90%", fixed: true, open: true
  });
};
this.Gws_Schedule_FacilityReservation = (function () {
  var requiredParams = function() {
    var repeatType = $('select[name="item[repeat_type]"]').val();
    var allday = $('input[type=checkbox][name="item[allday]"]').prop('checked');

    var $startOnEl;
    if (repeatType) {
      $startOnEl = $('input[name="item[repeat_start]"]');
    } else if (allday) {
      $startOnEl = $('input[name="item[start_on]"]');
    } else {
      $startOnEl = $('input[name="item[start_at]"]');
    }
    if (! $startOnEl || ! $startOnEl[0]) {
      return;
    }

    var startOn = SS_DateTimePicker.valueForExchange($startOnEl);
    if (! startOn) {
      return;
    }

    var $endOnEl;
    if (repeatType) {
      $endOnEl = $('input[name="item[repeat_end]"]');
    } else if (allday) {
      $endOnEl = $('input[name="item[end_on]"]');
    } else {
      $endOnEl = $('input[name="item[end_at]"]');
    }
    if (! $endOnEl || ! $endOnEl[0]) {
      return;
    }

    var endOn = SS_DateTimePicker.valueForExchange($endOnEl);
    if (! endOn) {
      return;
    }

    var facilityIds = [];
    $('.gws-schedule-facility table.ajax-selected tbody tr').each(function() {
      facilityIds.push($(this).data('id'));
    });
    if (facilityIds.length == 0) {
      return;
    }

    if (! repeatType) {
      repeatType = 'daily';
    }

    return {
      repeat_type: repeatType,
      allday: allday ? "allday" : "",
      start_on: startOn,
      end_on: endOn,
      facility_ids: facilityIds
    };
  };

  var optionalParams = function() {
    var params = {};
    var val;

    val = $('select[name="item[interval]"]').val();
    if (val) {
      params.interval = val;
    }

    var wdays = [];
    $('input[name="item[wdays][]"]:checked').each(function() {
      wdays.push($(this).val());
    });
    if (wdays.length > 0) {
      params.wdays = wdays;
    }

    val = $('input[name="item[repeat_base]"]:checked').val();
    if (val) {
      params.repeat_base = val;
    }

    return params;
  };

  var removeMisleadingOrUselessParams = function (formData) {
    var names = [];
    formData.forEach(function (value, name) {
      if (name.startsWith("item[") || name === "authenticity_token") {
        return;
      }
      if (names.includes(name)) {
        return;
      }
      names.push(name);
    });

    names.forEach(function (name) {
      formData.delete(name);
    });

    return formData;
  };

  var postData = function(extraParams) {
    var s = requiredParams();
    if (SS.isEmptyObject(s)) {
      return false;
    }

    var formData = new FormData($('form#item-form')[0]);
    removeMisleadingOrUselessParams(formData);

    formData.set("s[repeat_type]", s.repeat_type);
    formData.set("s[allday]", s.allday);
    formData.set("s[start_on]", s.start_on);
    formData.set("s[end_on]", s.end_on);
    s.facility_ids.forEach(function(value) {
      formData.append("s[facility_ids][]", value);
    });

    var o = optionalParams();
    if (!SS.isEmptyObject(o)) {
      if ("interval" in o) {
        formData.set("s[interval]", o.interval);
      }
      if ("wdays" in o) {
        o.wdays.forEach(function(value) { formData.append("s[wdays][]", value); });
      }
      if ("repeat_base" in o) {
        formData.set("s[repeat_base]", o.repeat_base);
      }
    }

    var allday = $('input[type=checkbox][name="item[allday]"]').prop('checked');
    var minHour = undefined;
    var maxHour = undefined;
    if (! allday) {
      try {
        var startAt = SS_DateTimePicker.momentValue($('input[name="item[start_at]"]'));
        var endAt = SS_DateTimePicker.momentValue($('input[name="item[end_at]"]'));
        minHour = startAt.hours();
        maxHour = endAt.hours() + (endAt.minutes() > 0 ? 1 : 0);
      } catch (e) {
        return false;
      }
    }
    if (minHour) {
      formData.set("d[min_hour]", minHour);
    }
    if (maxHour) {
      formData.set("d[max_hour]", maxHour);
    }

    var planId = $(".gws-schedule-facility").attr("data-plan-id");
    if (planId) {
      formData.set("item[id]", planId);
    }

    if (!SS.isEmptyObject(extraParams)) {
      for (var key in extraParams) {
        formData.set(key, extraParams[key]);
      }
    }

    return formData;
  }

  var changeVisibility = function() {
    var s = requiredParams();
    if (SS.isEmptyObject(s)) {
      $('.btn-confirm-facility-reservation').hide();
    } else {
      $('.btn-confirm-facility-reservation').show();
    }
  };

  function Gws_Schedule_FacilityReservation(options) {
    this.options = options;
    this.$html_facility_reservation = null;
    this.item_submit = null;
    this.confirm = this.options.confirm;

    this.render();
  }

  Gws_Schedule_FacilityReservation.prototype.render = function() {
    var self = this;

    $('.btn-confirm-facility-reservation').on('click', function (ev) {
      self.item_submit = false;
      self.confirmFacilityReservation();

      ev.preventDefault();
      return false;
    });

    $('form#item-form').on('submit', function(ev) {
      var data = postData({ submit: 1 });
      if (self.confirm || !data) {
        return true;
      }

      self.item_submit = true;
      $.ajax({
        method: 'POST',
        url: self.options.search_reservations_path,
        data: data,
        contentType: false,
        processData: false,
        cache: false,
        success: function(data) {
          self.$html_facility_reservation = $('<div></div>').html(data);
          if(self.$html_facility_reservation.find(".reservation-valid.free").length) {
            self.proceed();
            $('form#item-form').submit();
          } else {
            self.confirmFacilityReservation();
          }
        }
      });

      ev.preventDefault();
      return false;
    });

    $('select[name="item[repeat_type]"]').on('change', function() {
      self.confirm = false;
      changeVisibility();
    });

    $('input[name="item[repeat_start]"]').on('change', function() {
      self.confirm = false;
      changeVisibility();
    });

    $('input[name="item[repeat_end]"]').on('change', function() {
      self.confirm = false;
      changeVisibility();
    });

    $('.gws-schedule-facility .ajax-selected').on('change', function() {
      self.confirm = false;
      changeVisibility();
    });

    $('.gws-schedule-start-end-combo').on('ss:initialized', function() {
      self.confirm = false;
      changeVisibility();
    });

    changeVisibility();
  };

  Gws_Schedule_FacilityReservation.prototype.confirmFacilityReservation = function() {
    var self = this;

    var data = postData();
    if (!data) {
      return false;
    }

    if (self.$html_facility_reservation && self.$html_facility_reservation.html()) {
      $.colorbox({
        html: self.$html_facility_reservation.html(),
        maxWidth: "80%",
        maxHeight: "80%",
        fixed: true,
        open: true,
        onComplete: function() {
          self.colorboxEvent();
        }
      });
    } else {
      $.ajax({
        method: 'POST',
        url: self.options.search_reservations_path,
        data: data,
        processData: false,
        contentType: false,
        cache: false,
        success: function (data) {
          $.colorbox({
            html: data,
            maxWidth: "80%",
            maxHeight: "80%",
            fixed: true,
            open: true,
            onComplete: function() {
              self.colorboxEvent();
            }
          });
        }
      });
    }

    self.$html_facility_reservation = null;
    return true;
  };

  Gws_Schedule_FacilityReservation.prototype.colorboxEvent = function() {
    var self = this;

    $('#cboxLoadedContent .send .confirm').on('click', function(ev) {
      self.proceed();
      if (self.item_submit) {
        $('form#item-form').submit();
      }
      ev.preventDefault();
      return false;
    });
    $('#cboxLoadedContent .send .cancel').on('click', function(ev) {
      self.cancel();
      ev.preventDefault();
      return false;
    });
  };

  Gws_Schedule_FacilityReservation.prototype.proceed = function() {
    $.colorbox.close();
    this.confirm = true;
  };

  Gws_Schedule_FacilityReservation.prototype.cancel = function() {
    $.colorbox.close();
    this.confirm = false;
  };

  return Gws_Schedule_FacilityReservation;
})();
this.Gws_Memo_Message = (function () {
  function Gws_Memo_Message() {
  }

  Gws_Memo_Message.render = function () {
    $(".list-head .search").on("click", function () {
      $(".gws-memo-search").animate({ height: "toggle" }, "fast");
    });

    $(".gws-memo-search .reset").on("click", function () {
      $(".gws-memo-search input[type=text]").val("");
      $(".gws-memo-search input[type=checkbox]").val("");
      $(".gws-memo-search .search").trigger("click");
    });

    $('.cc-bcc-label').on("click", function () {
      $('.gws-addon-memo-member .cc-bcc').animate({ height: 'toggle' }, 'fast');
      return false;
    });

    $('.add-template').on("change", function () {
      if ($(this).val() === "") {
        return;
      }
      if ($('#item_format').val() === "html") {
        CKEDITOR.instances['item_html'].insertText($(this).val());
      } else {
        Webmail_Mail_Form.insertText($("#item_text"), $(this).val());
      }
      $(this).val("");
    });

    $(".send-mdn,.ignore-mdn").on("click", function () {
      if ($(this).hasClass('disabled')) {
        return false;
      }

      $.ajax({
        url: $(this).attr("href"),
        method: 'POST',
        dataType: 'json',
        data: {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content')
        },
        beforeSend: function () {
          return $(".send-mdn,.ignore-mdn").addClass('disabled');
        },
        success: function (data) {
          SS.notice(data.notice);
          return $(".request-mdn-notice").remove();
        }
      });
    });

    $(".icon-star a").on("click", function () {
      var $wrap = $(this).parent();
      var url;
      if ($wrap.hasClass('on')) {
        url = $(this).attr('href') + '/unset_star';
      } else {
        url = $(this).attr('href') + '/set_star';
      }
      $.ajax({
        url: url,
        method: 'POST',
        dataType: 'json',
        data: {
          _method: 'put'
        },
        success: function (data) {
          if (data.action === 'set_star') {
            $wrap.removeClass('off').addClass('on');
          } else {
            $wrap.removeClass('on').addClass('off');
          }
          if (data.notice) {
            SS.notice(data.notice);
          }
        }
      });
      return false;
    });
  };

  Gws_Memo_Message.buildForm = function (action, confirm) {
    var checked = $(".list-item input:checkbox:checked").map(function () {
      return $(this).val();
    });
    if (checked.length === 0) {
      return false;
    }
    var token = $('meta[name="csrf-token"]').attr("content");
    var form = $("<form/>", { action: action, method: "post", data: { confirm: confirm } });
    form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
    var i, len;
    for (i = 0, len = checked.length; i < len; i++) {
      var id = checked[i];
      form.append($("<input/>", { name: "ids[]", value: id, type: "hidden" }));
    }
    return form;
  };

  return Gws_Memo_Message;

})();
function Gws_Memo_Folder() {
}

Gws_Memo_Folder.render = function () {
  return $("#addon-gws-agents-addons-group_permission").hide();
};
function Gws_Memo_Filter() {
}

Gws_Memo_Filter.render = function () {
  return $("#addon-gws-agents-addons-group_permission").hide();
};
this.Gws_Monitor_Topic = (function () {
  function Gws_Monitor_Topic() {
  }

  Gws_Monitor_Topic.render = function () {
    $(".public").on("click", function () {
      var $this, action, confirm, form, token;
      token = $('meta[name="csrf-token"]').attr('content');
      $this = $(this);
      action = $this.data('ss-action');
      confirm = $this.data('ss-confirm');
      form = $("<form/>", {
        action: action,
        method: "post",
        data: {
          confirm: confirm
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    $(".preparation").on("click", function () {
      var $this, action, confirm, form, token;
      token = $('meta[name="csrf-token"]').attr('content');
      $this = $(this);
      action = $this.data('ss-action');
      confirm = $this.data('ss-confirm');
      form = $("<form/>", {
        action: action,
        method: "post",
        data: {
          confirm: confirm
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    $(".question_not_applicable").on("click", function () {
      var form, id, token;
      token = $('meta[name="csrf-token"]').attr('content');
      id = $("#item_id").val();
      form = $("<form/>", {
        action: id + "/question_not_applicable",
        method: "post",
        data: {
          confirm: i18next.t('gws/monitor.confirm.question_not_applicable')
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
    return $(".answered").on("click", function () {
      var form, id, token;
      token = $('meta[name="csrf-token"]').attr('content');
      id = $("#item_id").val();
      form = $("<form/>", {
        action: id + "/answered",
        method: "post",
        data: {
          confirm: i18next.t('gws/monitor.confirm.answer')
        }
      });
      form.append($("<input/>", {
        name: "authenticity_token",
        value: token,
        type: "hidden"
      }));
      return form.appendTo(document.body).submit();
    });
  };

  Gws_Monitor_Topic.buildForm = function (action, confirm) {
    var checked, form, i, id, len, token;
    checked = $(".list-item input:checkbox:checked").map(function () {
      return $(this).val();
    });
    if (checked.length === 0) {
      return false;
    }
    token = $('meta[name="csrf-token"]').attr('content');
    form = $("<form/>", {
      action: action,
      method: "post",
      data: {
        confirm: confirm
      }
    });
    form.append($("<input/>", {
      name: "authenticity_token",
      value: token,
      type: "hidden"
    }));
    for (i = 0, len = checked.length; i < len; i++) {
      id = checked[i];
      form.append($("<input/>", {
        name: "ids[]",
        value: id,
        type: "hidden"
      }));
    }
    return form;
  };

  Gws_Monitor_Topic.renderForm = function (opts) {
    if (opts == null) {
      opts = {};
    }
    $("input.date").datetimepicker({
      lang: "ja",
      timepicker: false,
      format: 'Y/m/d',
      closeOnDateSelect: true,
      scrollInput: false,
      maxDate: opts["maxDate"]
    });
    return $("input.datetime").datetimepicker({
      lang: "ja",
      roundTime: 'ceil',
      step: 30,
      maxDate: opts["maxDate"]
    });
  };

  return Gws_Monitor_Topic;

})();
function Gws_Portal(selector, settings) {
  var options = {
    autogenerate_stylesheet: true,
    resize: {
      enabled: true,
      max_size: [4, 10]
    },
    widget_base_dimensions: ['auto', 120],
    widget_margins: [10, 10],
    min_cols: 1,
    max_cols: 4
  };
  if (settings && settings['readonly']) {
    this.readonly = true;
    options['resize'] = { enabled: false };
    options['draggable'] = { enabled: false, handle: 'disable' };
  }
  if (settings && settings['max_rows']) {
    options['max_rows'] = settings['max_rows'];
  }

  this.el = $(selector);
  this.gs = this.el.find("ul.portlets").gridster(options).data('gridster');
}

Gws_Portal.prototype.addItems = function(items) {
  var _this = this;
  $.each(items, function(idx, item) {
    _this.addItem(item);
  });
};

Gws_Portal.prototype.addItem = function(item) {
  var id = item._id.$oid;

  var li = this.gs.add_widget(
    '<li class="portlet-item" data-id="' + id + '"></li>',
    item.grid_data.size_x,
    item.grid_data.size_y,
    item.grid_data.col,
    item.grid_data.row
  );
  if (! li) {
    return;
  }
  li.data('id', id);

  var html = this.el.find(".portlet-html[data-id='" + id + "']");
  if (html.length) {
    html.prependTo(li);
  }
};

Gws_Portal.prototype.autoResizeItem = function(widget, height) {
  var base_y = this.gs.options.widget_base_dimensions[1];
  var extra  = ((height % base_y) > (base_y / 2)) ? 1 : 0;
  var size_x = widget.data('sizex');
  var size_y = Math.floor(height / base_y) + extra;

  if (widget.data('sizey') < size_y) {
    this.gs.resize_widget(widget, size_x, size_y);
  }
};

Gws_Portal.prototype.setSerializeEvent = function(selector) {
  var _this = this;
  _this.updateUrl = $(selector).data('href');
  $(selector).on("click", function() {
    _this.serialize();
  });
};

Gws_Portal.prototype.setResetEvent = function(selector) {
  var _this = this;
  $(selector).on("click", function() {
    var list = [];
    _this.el.find(".portlet-item").each(function() {
      list.push($(this).clone());
    });
    _this.gs.remove_all_widgets();

    $.each(list, function(index, li) {
      _this.gs.add_widget(li, li.data('sizex'), li.data('sizey'));
    });
  });
};

Gws_Portal.prototype.serialize = function() {
  var _this = this;
  var list = {};
  _this.el.find("li.portlet-item").each(function() {
    var li = $(this);
    var id = li.data('id');
    list[id] = _this.gs.serialize(li)[0];
  });

  $.ajax({
    url: _this.updateUrl,
    method: 'POST',
    dataType: 'json',
    data: {
      _method: 'put',
      authenticity_token: $('meta[name="csrf-token"]').attr('content'),
      json: JSON.stringify(list)
    },
    success: function(data) {
      SS.notice(data.message);
    },
    error: function (xhr, _status, _error) {
      if (xhr.responseJSON && xhr.responseJSON.message) {
        SS.notice(xhr.responseJSON.message);
      } else {
        SS.notice("Error!!");
      }
    }
  });
};
Gws_Elasticsearch_Highlighter = function () {
}

Gws_Elasticsearch_Highlighter.prototype = {
  render: function () {
    if (location.hash) {
      $(location.hash).css('border', '1px solid red');
    }
  }
};
this.Gws_Discussion_Thread = (function () {
  function Gws_Discussion_Thread() {
  }

  Gws_Discussion_Thread.render = function (user) {
    //temp file
    var appendSelectedFile = function (selected, fileId, humanizedName) {
      var span = $('<span></span>');
      var img = $('<img src="/assets/img/gws/ic-file.png" alt="" />');
      var a = $('<a target="_blank" rel="noopener"></a>');
      var input = $('<input type="hidden" name="item[file_ids][]" class="file-id" />');
      var icon = $("<i class=\"material-icons md-18 md-inactive deselect\">close</i>");

      span.attr("data-file-id", fileId);
      span.attr("id", "file-" + fileId);
      a.text(humanizedName);
      a.attr("href", "/.u" + user + "/apis/temp_files/" + fileId + "/view");
      input.attr("value", fileId);
      icon.on("click", function (e) {
        $(this).parent("span").remove();
        if ($(selected).find("[data-file-id]").length <= 0) {
          $(selected).hide();
        }
        return false;
      });

      span.append(img);
      span.append(a);
      span.append(icon);
      span.append(input);

      $(selected).show();
      $(selected).append(span);
    };

    $('a.ajax-box').data('on-select', function ($item) {
      var selected = $.colorbox.element().closest(".comment-files").find(".selected-files");
      var $data = $item.closest('[data-id]');
      var fileId = $data.data('id');
      var humanizedName = $data.data('humanized-name');
      appendSelectedFile(selected, fileId, humanizedName);
      return $.colorbox.close();
    });

    var options = {
      select: function (files, dropArea) {
        $(files).each(function (i, file) {
          var fileId, humanizedName, selected;
          selected = $(dropArea).closest(".comment-files").find(".selected-files");
          fileId = file["_id"];
          humanizedName = file["name"];
          return appendSelectedFile(selected, fileId, humanizedName);
        });
        return false;
      }
    };

    $(".comment-files .upload-drop-area").each(function() {
      new SS_Addon_TempFile(this, user, options);
    });

    // reply
    $(".open-reply").on('click', function () {
      $(this).closest(".addon-body").next(".reply").show();
      $(this).remove();
      return false;
    });

    //rely contriutor
    $(".reply[data-topic]").each(function () {
      var topic = $(this).attr("data-topic");
      var setContributor = function () {
        $('.discussion-contributor' + topic + ' input#item_contributor_model').val($(this).data('model'));
        $('.discussion-contributor' + topic + ' input#item_contributor_id').val($(this).data('id'));
        return $('.discussion-contributor' + topic + ' input#item_contributor_name').val($(this).data('name'));
      };
      $(this).find('.discussion-contributor' + topic + ' input[name="tmp[contributor]"]').on('change', setContributor);
      return $(this).find('.discussion-contributor' + topic + ' input[name="tmp[contributor]"]:checked').each(setContributor);
    });
  };

  return Gws_Discussion_Thread;

})();
this.Gws_Discussion_Unseen = (function () {
  function Gws_Discussion_Unseen() {
  }

  Gws_Discussion_Unseen.url = null;

  Gws_Discussion_Unseen.intervalID = null;

  Gws_Discussion_Unseen.intervalTime = null;

  Gws_Discussion_Unseen.timestamp = null;

  Gws_Discussion_Unseen.renderUnseen = function (url, intervalTime, timestamp) {
    this.url = url;
    this.intervalTime = intervalTime;
    this.timestamp = timestamp;
    if (this.url && this.intervalTime && this.timestamp) {
      return this.intervalID = setInterval(this.checkMessage, this.intervalTime);
    }
  };

  Gws_Discussion_Unseen.checkMessage = function () {
    return $.ajax({
      url: Gws_Discussion_Unseen.url,
      success: function (data, status) {
        var timestamp;
        timestamp = parseInt(data);
        if (timestamp > Gws_Discussion_Unseen.timestamp) {
          $(".gws-discussion-unseen").show();
          return clearInterval(Gws_Discussion_Unseen.intervalID);
        }
      }
    });
  };

  return Gws_Discussion_Unseen;

})();
Gws_Attendance = function (el, options) {
  this.el = el;
  this.$el = $(el);
  this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
  this.now = new Date(options.now);
  this.render();
};

Gws_Attendance.prototype.render = function() {
  var _this = this;

  this.$el.find('button[name=punch]').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var action = $(this).data('action');
    var confirm = $(this).data('confirm');
    _this.onPunchClicked(action, confirm);
  });

  this.$el.find('button[name=edit]').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var action = $(this).data('action');
    var confirm = $(this).data('confirm');
    _this.onEditClicked(action, confirm);
  });

  this.$el.find('.reason-tooltip').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.hideToolbar();
    _this.hideTooltip();
    $(this).find('.reason').show();
  });

  this.$el.find('.leave-file-tooltip').on('click', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    var href = $(this).attr("data-href");
    $.colorbox({ href: href });
  });

  this.$el.find('select[name=year_month]').on('change', function() {
    var val = $(this).val();
    if (! val) {
      return;
    }
    location.href = _this.options.indexUrl.replace(':year_month', val);
  });

  this.$toolbar.find(".punch").on("click", function() {
    _this.onPunchClicked($(this).attr("href"), $(this).data("confirmation"), $(this).data("type"));
    return false;
  });

  $(document).on('click', this.el + ' .time-card .time', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.onClickTime($(this));
  });

  $(document).on('click', this.el + ' .time-card .memo', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.onClickMemo($(this));
  });

  $(document).on('click', this.el + ' .time-card .working-time-edit', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();

    _this.onClickWorkingTime($(this));
  });

  $(document).on('click', function() {
    _this.hideToolbar();
    _this.hideTooltip();
  });
};

Gws_Attendance.prototype.onPunchClicked = function(action, message) {
  if (! action) {
    return;
  }

  if (message) {
    if (! confirm(message)) {
      return;
    }
  }

  var token = $('meta[name="csrf-token"]').attr('content');

  $form = $('<form/>', { action: action, method: 'post' });
  $form.append($("<input/>", { name: "authenticity_token", value: token, type: "hidden" }));
  $('body').append($form);
  $form.submit();
};

Gws_Attendance.prototype.onEditClicked = function(action, message) {
  if (!action) {
    return
  }

  if (message) {
    if (!confirm(message)) {
      return;
    }
  }

  $a = $('<a />', { href: action });
  $a.colorbox({ open: true, width: '90%' });
};

Gws_Attendance.prototype.hideToolbar = function() {
  this.$toolbar.hide();
};

Gws_Attendance.prototype.hideTooltip = function() {
  this.$el.find('.reason-tooltip .reason').hide();
};

Gws_Attendance.prototype.onClickTime = function($cell) {
  this.onClickCell($cell, this.options.timeUrl);
};

Gws_Attendance.prototype.onClickMemo = function($cell) {
  this.onClickCell($cell, this.options.memoUrl);
};
Gws_Attendance.prototype.onClickWorkingTime = function($cell) {
  this.onClickCell($cell, this.options.workingTimeUrl);
};

Gws_Attendance.prototype.setFocus = function($cell) {
  this.$el.find('.time-card .time').removeClass('focus');
  this.$el.find('.time-card .memo').removeClass('focus');
  this.$el.find('.time-card .working_time').removeClass('focus');
  $cell.addClass('focus');
};

Gws_Attendance.prototype.isCellToday = function($cell) {
  return $cell.closest('tr').hasClass('current');
};

Gws_Attendance.prototype.onClickCell = function($cell, urlTemplate) {
  this.hideTooltip();

  if (! $cell.data('day')) {
    return;
  }

  this.setFocus($cell);

  if (!this.options.editable && !this.isCellToday($cell)) {
    this.$toolbar.hide();
    return;
  }

  var day = $cell.data('day');
  var type = $cell.data('type');
  var mode = $cell.data('mode');

  var punchable = this.isCellToday($cell);
  var editable = this.options.editable;

  if (type === "memo") {
    if (this.isCellToday($cell)) {
      editable = true;
    }
  }

  if (type === "working_time") {
    if (this.isCellToday($cell)) {
      editable = true;
    }
  }

  var showsToolbar = false;
  if (mode === "punch" && punchable && this.options.punchUrl) {
    var url = this.options.punchUrl;
    url = url.replace(':type', type);

    this.$toolbar.find('.edit').hide();
    this.$toolbar.find('.punch').attr('href', url).show();
    showsToolbar = true;
  }

  if (mode === "edit" && editable) {
    var url = urlTemplate;
    url = url.replace(':day', day);
    url = url.replace(':type', type);

    this.$toolbar.find('.punch').hide();
    this.$toolbar.find('.edit').attr('href', url).show();
    showsToolbar = true;
  }

  if (! showsToolbar) {
    this.$toolbar.hide();
    return;
  }

  var offset = $cell.offset();
  if ($cell.hasClass('top')) {
    offset.top -= this.$toolbar.outerHeight();
  } else {
    offset.top += $cell.outerHeight();
  }

  // call `show` and then call `offset`. order is important
  this.$toolbar.show();
  this.$toolbar.offset(offset);
};
Gws_Attendance_Portlet = function (el, options) {
  // this.el = el;
  this.$el = $(el);
  // this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
  // this.now = new Date(options.now);
  this.render();
};

Gws_Attendance_Portlet.prototype.render = function() {
  var _this = this;

  this.$el.find('button[name=punch]').on('click', function() {
    _this.punch($(this), $(this).closest('tr').data('field-name'));
  });

  this.$el.find('button[name=edit]').on('click', function() {
    _this.edit($(this), $(this).closest('tr').data('field-name'));
  });
};

Gws_Attendance_Portlet.prototype.punch = function($button, fieldName) {
  $button.attr('disabled', 'disabled');
  if (! confirm(this.options.confirmMessage)) {
    $button.removeAttr('disabled');
    return;
  }

  var url = this.options.punchUrl.replace(':TYPE', fieldName);
  var _this = this;
  $.ajax({
    url: url,
    method: 'POST',
    data: { ref: this.options.ref },
    dataType: 'json',
    success: function(data) {
      alert(_this.options.successMessage);
      location.reload();
    },
    error: function(xhr, status, error) {
      alert(xhr.responseJSON.join("\n"));
    },
    complete: function() {
      $button.removeAttr('disabled');
    }
  });
};

Gws_Attendance_Portlet.prototype.edit = function($button, fieldName) {
  $button.attr('disabled', 'disabled');

  var url = this.options.editUrl.replace(':TYPE', fieldName);
  $a = $('<a/>', { href: url });
  $a.colorbox({
    open: true,
    width: '90%',
    onClosed: function() { $button.removeAttr('disabled'); }
  });
};
this.Gws_Presence_User = (function () {
  function Gws_Presence_User() {}

  Gws_Presence_User.render = function () {
    // selector
    $(document).on("click", function() {
      $(".presence-state-selector").hide();
        return true;
    });
    $(".presence-state-selector").on("click", function() {
      return false;
    });
    $(".presence-state-selector [data-value]").on("click", function() {
      var $this = $(this);
      var $presenceState = $this.closest(".presence-state-selector");
      var id = $presenceState.attr("data-id");
      var url = $presenceState.attr("data-url");
      var value = $this.attr("data-value");
      $.ajax({
        url: url,
        type: "POST",
        data: {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content'),
          presence_state: value,
        },
        success: function(data) {
          Gws_Presence_User.changedState(id, data);
          $(".presence-state-selector").hide();
        },
        error: function (xhr, status, error) {
          alert(xhr.responseJSON.join("\n"));
        },
      });
      return false;
    });
    $(".editable .select-presence-state,.editable .presence-state").on("click", function(){
      $(".presence-state-selector").closest("li.portlet-item").css("z-index", 0);
      $(".presence-state-selector").hide();
      $(this).closest("li.portlet-item").css("z-index", 1000);
      $(this).closest("td").find(".presence-state-selector").show();
      return false;
    });
    // ajax-text-field
    $(".ajax-text-field").on("click", function(){
      Gws_Presence_User.toggleForm(this);
      return false;
    });
    $(".ajax-text-field").next(".editicon").on("click", function(){
      $(this).prev(".ajax-text-field").trigger('click');
      return false;
    })
  };

  Gws_Presence_User.changedState = function (id, data) {
    var presence_state = data["presence_state"] || "";
    var presence_state_label = data["presence_state_label"];
    var presence_state_style = data["presence_state_style"];
    var state = $("tr[data-id=" + id + "] .presence-state");
    var selector = $("tr[data-id=" + id + "] .presence-state-selector");

    state.removeClass();
    state.addClass('presence-state');
    state.addClass(presence_state_style);
    state.text(presence_state_label);

    selector.find('[data-value="' + presence_state + '"] .selected-icon').css('visibility', 'visible');
    selector.find('[data-value!="' + presence_state + '"] .selected-icon').css('visibility', 'hidden');
  }

  Gws_Presence_User.toggleForm = function (ele) {
    var state = $(ele).attr("data-tag-state");
    var original = $(ele).attr("data-original-tag");
    var form = $(ele).attr("data-form-tag");
    var value = $(ele).text() || $(ele).val();
    var name = $(form).attr("name");
    var id = $(form).attr("data-id");
    var url = $(form).attr("data-url");
    var errorOccurred = false;

    if (state == "original") {
      form = $(form);
      form.attr("data-original-tag", $(ele).attr("data-original-tag"));
      form.attr("data-form-tag", $(ele).attr("data-form-tag"));
      form.val(value);
      form.focusout(function (e) {
        if (errorOccurred) {
          return true;
        }
        var data = {
          _method: 'put',
          authenticity_token: $('meta[name="csrf-token"]').attr('content'),
        };
        data[name] = $(form).val();
        $.ajax({
          url: url,
          type: "POST",
          data: data,
          success: function(data) {
            $(form).val(data[name]);
            Gws_Presence_User.toggleForm(form);
          },
          error: function (xhr, status, error) {
            alert(xhr.responseJSON.join("\n"));
            errorOccurred = true;
          },
        });
        return false;
      });
      form.keypress(function (e) {
        if (e.which == SS.KEY_ENTER) {
          var data = {
            _method: 'put',
            authenticity_token: $('meta[name="csrf-token"]').attr('content'),
          };
          data[name] = $(form).val();
          $.ajax({
            url: url,
            type: "POST",
            data: data,
            success: function(data) {
              $(form).val(data[name]);
              Gws_Presence_User.toggleForm(form);
            },
            error: function (xhr, status, error) {
              alert(xhr.responseJSON.join("\n"));
              errorOccurred = true;
            },
          });
          return false;
        }
      });
      var replaced = form.uniqueId();
      $(ele).replaceWith(form);
      $(replaced).focus();
    }
    else {
      original = $(original).text(value);
      original.attr("data-original-tag", $(ele).attr("data-original-tag"));
      original.attr("data-form-tag", $(ele).attr("data-form-tag"));
      original.on("click", function(){
        Gws_Presence_User.toggleForm(this);
        return false;
      });
      original.uniqueId();
      $(ele).replaceWith(original);

      // support same name's ajax-text-field
      $(".ajax-text-field[data-id='" + original.attr("data-id") + "'][data-name='" + original.attr("data-name") + "']").text(value);
    }
  };

  return Gws_Presence_User;
})();

this.Gws_Presence_User_Reload = (function () {
  function Gws_Presence_User_Reload() {}

  Gws_Presence_User_Reload.render = function (opts) {
    if (opts == null) {
      opts = {};
    }

    var table_url = opts["url"];
    var paginate_params = opts["paginate_params"];
    var page = opts["page"];

    $(".group-users .reload").on("click", function () {
      var param = $.param({
        "s": {"keyword": $(".group-users [name='s[keyword]']").val()},
        "paginate_params": paginate_params,
        "page": page
      });
      $.ajax({
        url: table_url + '?' + param,
        beforeSend: function () {
          $(".group-users .data-table-wrap").html(SS.loading);
        },
        success: function (data) {
          $(".group-users .data-table-wrap").html(data);
          var time = $(".group-users .data-table-wrap").find("time");
          $(".group-users .list-head time").replaceWith(time).show();
          time.show();
        }
      });
    });
    $(".group-users .list-head .search").on("submit", function () {
      var param = $.param({
        "s": {"keyword": $(".group-users [name='s[keyword]']").val()},
        "paginate_params": paginate_params,
      });
      $.ajax({
        url: table_url + '?' + param,
        beforeSend: function () {
          $(".group-users .data-table-wrap").html(SS.loading);
        },
        success: function (data) {
          $(".group-users .data-table-wrap").html(data);
          var time = $(".group-users .data-table-wrap").find("time");
          $(".group-users .list-head time").replaceWith(time);
          time.show();
        },
        error: function (xhr, status, error) {
          $(".group-users .data-table-wrap").html("");
        }
      });
      return false;
    });
  }

  return Gws_Presence_User_Reload;
})();
function Gws_Share_FolderToolbar(el, options) {
  this.$el = $(el);
  this.options = options;
  this.render();
}

Gws_Share_FolderToolbar.prototype.render = function () {
  var self = this;

  this.$el.find(".btn-create-folder").on("click", function() {
    self.createFolder($(this));
  });

  this.$el.find(".btn-create-root-folder").on("click", function() {
    self.createFolder($(this));
  });

  this.$el.find(".btn-rename-folder").on("click", function() {
    self.renameFolder($(this), { success: { callback: self.refresh } });
  });

  this.$el.find(".btn-delete-folder").on("click", function() {
    self.deleteFolder($(this));
  });

  this.$el.find(".btn-edit-folder").on("click", function() {
    self.editFolder($(this));
  });

  this.$el.find(".btn-refresh-folder").on("click", function() {
    self.refreshFolder();
  });
};

Gws_Share_FolderToolbar.prototype.createFolder = function ($button, options) {
  var href = $button.data("href");
  if (href) {
    location.href = href;
    return;
  }

  var api = $button.data("api");
  if (! api) {
    return;
  }

  var success = $button.data("success");
  if (! success && options) {
    success = options.success;
  }
  var error = $button.data("error");
  if (! error && options) {
    error = options.error;
  }

  var self = this;

  $.colorbox({
    href: api, open: true, fixed: true, with: "90%", height: "90%",
    onComplete: function() {
      SS.ajaxForm("#cboxLoadedContent form", {
        success: function(data) {
          $.colorbox.close();
          if (success && success.redirect_to) {
            var id;
            if (data) {
              id = data.id;
              if (! id) {
                id = data._id;
              }
            }

            location.href = success.redirect_to.replace(/:id/, id);
            return;
          }
          if (success && success.reload) {
            location.reload();
            return;
          }
          if (success && success.callback) {
            success.callback.call(self, data);
          }
        },
        error: function(xhr) {
          $.colorbox.close();

          if (xhr.responseJSON && xhr.responseJSON.length > 0) {
            alert(xhr.responseJSON.join("\n"));
          } else if (error && error.message) {
            alert(error.message);
          }
        }
      });
    }
  });
};

Gws_Share_FolderToolbar.prototype.refresh = function (data) {
  if (! data) {
    return;
  }

  this.$el.find(".folder-name").text(data.name);
  this.refreshFolder();
};

Gws_Share_FolderToolbar.prototype.renameFolder = Gws_Share_FolderToolbar.prototype.createFolder;
Gws_Share_FolderToolbar.prototype.deleteFolder = Gws_Share_FolderToolbar.prototype.createFolder;
Gws_Share_FolderToolbar.prototype.editFolder = Gws_Share_FolderToolbar.prototype.createFolder;

Gws_Share_FolderToolbar.prototype.refreshFolder = function () {
  if (!this.options.treeNavi) {
    return;
  }

  this.options.treeNavi.refresh();
};
Gws_Affair_Menu = function (current, sessionKey) {
  this.current = current;
  this.sessionKey = sessionKey;
  this.render();
};

Gws_Affair_Menu.prototype.render = function() {
  var self = this;
  this.initNarrow();
  $(".toggle-narrow-page").on("click", function(){
    var $a = $(this);
    var $h3 = $a.closest("h3");
    var $narrow = $h3.next(".narrow-page");

    if ($narrow.hasClass("show")) {
      self.hideNarrow($narrow, "fast");
      $a.removeClass("down");
      self.updateSession();
    } else {
      self.showNarrow($narrow, "fast");
      $a.addClass("down");
      self.updateSession();
    }
    return false;
  });
};

Gws_Affair_Menu.prototype.showNarrow = function(ele, duration) {
  $(ele).removeClass("hide");
  $(ele).addClass("show");
  $(ele).show(duration);
};

Gws_Affair_Menu.prototype.hideNarrow = function(ele, duration) {
  $(ele).removeClass("show");
  $(ele).hide(duration, function(){
    $(this).addClass("hide");
  });
};

Gws_Affair_Menu.prototype.getSession = function() {
  var navi = sessionStorage.getItem(this.sessionKey);
  if (navi) {
    navi = navi.split(",")
  } else {
    navi = [];
  }
  return navi;
};

Gws_Affair_Menu.prototype.updateSession = function() {
  var navi = $(".narrow-page[data-navi].show").map(function() { return $(this).attr("data-navi") }).toArray();
  sessionStorage.setItem(this.sessionKey, navi.join(","));
};

Gws_Affair_Menu.prototype.initNarrow = function () {
  var self = this;
  $(".toggle-narrow-page").each(function(){
    var $a = $(this);
    var $h3 = $a.closest("h3");
    var $narrow = $h3.next(".narrow-page");

    var navi = self.getSession();
    var content = $narrow.attr("data-navi");

    if (navi.includes(content) || content == "<%= current_navi %>") {
      self.showNarrow($narrow);
      $a.addClass("down");
    } else {
      self.hideNarrow($narrow);
      $a.removeClass("down");
    }
  });
  self.updateSession();
};
Gws_Affair_OvertimeFile = function (options) {
  this.holidayUrl = options["holidayUrl"];
  this.capitalUrl = options["capitalUrl"];
  this.$dateStartEl = $('[name="item[start_at_date]"]');
  this.$dateEndEl = $('[name="item[end_at_date]"]');
  this.render();
};

Gws_Affair_OvertimeFile.prototype.render = function() {
  var self = this;

  // 開始日を変更した際に、終了日を設定する
  // 開始日が週休日、祝日の場合、振替申請を切り替える
  self.$dateStartEl.on("ss:changeDateTime", function() {
    var startDate = SS_DateTimePicker.momentValue(self.$dateStartEl);
    if (startDate) {
      SS_DateTimePicker.momentValue(self.$dateEndEl, startDate);
      self.toggleCompensatory(startDate);
    }
  });
  //self.$dateStartEl.trigger("ss:changeDateTime");
  self.toggleCompensatory(SS_DateTimePicker.momentValue(self.$dateStartEl));

  // 申請対象を選択した際に、原資区分を設定する
  $(".mod-gws-affair_file_target_user .ajax-box").data("on-select", function($item) {
    SS_SearchUI.defaultSelector($item);

    var data = $item.closest("[data-id]");
    var uid = data.data("id");
    self.loadEffectiveCapital(uid);
  });
  if ($(".selected-capital .capital").length == 0) {
    self.loadEffectiveCapital(self.findTargetUser());
  } else {
    $(".selected-capital .deselect").on("click", function() {
      $(".selected-capital").html("");
      self.loadEffectiveCapital(self.findTargetUser());
      return false;
    });
  }

  // 振替申請
  $(".open-compensatory").on("click", self.openCompensatory);
  $(".select-compensatory").on("change", self.toggleSelectCompensatoryMinute);
  $(".select-compensatory").trigger("change");

  // 振替申請が未設定の場合の警告を表示する（基本的に土日・祝日は振替として申請しなければならない）
  $("input:submit").on("click.form_alert", self.compensatoryFormAlert);

  // 緊急時はこちら
  $(".select-capital .ajax-box").data("on-select", function($item) {
    self.selectCapital($item);
  });
};

Gws_Affair_OvertimeFile.prototype.findTargetUser = function() {
  var $user = $(".mod-gws-affair_file_target_user .ajax-selected [data-id]:first");
  if ($user.length > 0) {
    return $user.closest("[data-id]").data("id");
  } else {
    return null;
  }
};

Gws_Affair_OvertimeFile.prototype.toggleCompensatory = function(startDate) {
  var self = this;
  var url = self.holidayUrl;
  var uid = self.findTargetUser();
  var ymd = startDate.format("YYYYMMDD");
  if (!uid) {
    return
  }

  url = url.replace("UID", uid);
  url = url.replace("YMD", ymd);
  $.get(url, function(data){
    // class と label の追加
    var label = [];
    $('.overtime-date').text("");
    $('.overtime-date').removeClass("leave-day");
    $('.overtime-date').removeClass("weekly-leave-day");
    $('.overtime-date').removeClass("holiday");
    if (data["leave_day"]) {
      $('.overtime-date').addClass("leave-day");
    }
    if (data["weekly_leave_day"]) {
      $('.overtime-date').addClass("weekly-leave-day");
      label.push('週休日');
    }
    if (data["holiday"]) {
      $('.overtime-date').addClass("holiday");
      label.push('祝日');
    }
    if (label.length > 0) {
      $('.overtime-date').text(" (" + label.join(",") + "）");
    }

    // 振替表示、非表示
    if (data["holiday"] && data["weekly_leave_day"]) {
      // 祝日かつ週休日
      $(".default-compensatory").show();
      $(".holiday-compensatory").show();
    } else if (data["holiday"]) {
      // 祝日
      $(".default-compensatory").hide();
      $(".holiday-compensatory").show();
    } else {
      $(".default-compensatory").show();
      $(".holiday-compensatory").hide();
    }
  });
};

Gws_Affair_OvertimeFile.prototype.openCompensatory = function() {
  $(this).next(".compensatory-with-date").show();
  $(this).remove();
  return false;
};

Gws_Affair_OvertimeFile.prototype.toggleSelectCompensatoryMinute = function() {
  $(".select-compensatory").each(function() {
    var val = $(this).val();
    if (val && val > 0) {
      $(this).closest("dd").find(".open-compensatory").show();
    } else {
      $(this).closest("dd").find(".open-compensatory").hide();
    }
  });
};

Gws_Affair_OvertimeFile.prototype.compensatoryFormAlert = function(e) {
  var submit = this;

  // 土日・祝日
  if (!$('.overtime-date').hasClass("leave-day")) {
    return true;
  }

  // 振替なし
  var minute = 0;
  $(".select-compensatory").map(function() {
    var val = parseInt($(this).val());
    if (Number.isInteger(val)) {
      minute += val;
    }
  });
  if (minute > 0) {
    return true;
  }

  // show alert
  var div = $('<div id="alertExplanation" class="errorExplanation">');
  div.append("<h2>時間外申請</h2>");
  div.append("<p>週休日・祝日の時間外について</p>")
  div.append('<ul><li style="white-space: nowrap;">週休日の振替又は代休日の設定がされておりません。<br />入力画面に戻るをクリックして、振替日等を設定してから保存をお願いします。<br />なお、特別な理由で時間外勤務又は休日勤務の場合は、このまま保存してください。</li></ul>');
  var footer = $(document.createElement("footer")).addClass('send');
  footer.append('<button name="button" type="button" class="btn-primary save">保存する</button>');
  footer.append('<button name="button" type="button" class="btn-default cancel">入力画面に戻る</button>');
  $.colorbox({
    html: div.get(0).outerHTML + footer.get(0).outerHTML,
    maxHeight: "80%",
    fixed: true
  });
  $("#cboxLoadedContent").find(".save").on("click", function () {
    $(submit).off(".form_alert");
    return $(submit).trigger("click");
  });
  $("#cboxLoadedContent").find(".cancel").on("click", function () {
    $.colorbox.close();
    return false;
  });

  e.preventDefault();
  return false;
};

Gws_Affair_OvertimeFile.prototype.loadEffectiveCapital = function(uid) {
  var self = this;
  var url = self.capitalUrl.replace("UID", uid);

  $(".selected-capital").html(SS.loading);
  $.get(url, function(html){
    $(".selected-capital").html(html);
  });
};

Gws_Affair_OvertimeFile.prototype.selectCapital = function($item) {
  var self = this;
  var anchorAjaxBox = SS_SearchUI.anchorAjaxBox;

  var data = $item.closest("[data-id]");
  var id = data.data("id");
  var div = $('<div class="caiptal emergency" />').attr("data-id", id);
  var name = data.data("name") || data.find(".select-item").text() || item.text() || data.text();
  var input1 = anchorAjaxBox.closest("dl").find(".hidden-ids").clone(false);
  var input2 = anchorAjaxBox.closest("dl").find(".capital-state").clone(false);
  var a = $('<a class="deselect btn" href="#">取消</a>');

  a.on("click", function() {
    $(".selected-capital").html("");
    self.loadEffectiveCapital(self.findTargetUser());
    return false;
  });

  input1 = input1.val(id).removeClass("hidden-ids");
  name += "（緊急）"
  input2.attr("value", "emergency");

  div.append(input1);
  div.append(input2);
  div.append(name);
  div.append(a);

  anchorAjaxBox.closest("dl").find(".selected-capital").html(div);
  anchorAjaxBox.closest("dl").find(".selected-capital").trigger("change");
};
Gws_Affair_ShiftRecords = function (el, options) {
  this.el = el;
  this.$el = $(el);
  this.$toolbar = this.$el.find('.cell-toolbar');
  this.options = options;
  this.render();
};

Gws_Affair_ShiftRecords.prototype.render = function() {
  var _this = this;

  $(document).on('click', this.el + ' .shift-record', function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    _this.onClickCell($(this));
  });

  $(this.el).find(".wrap-table").scroll(function () {
    _this.$toolbar.hide();
  });

  _this.$toolbar.hide();
};

Gws_Affair_ShiftRecords.prototype.setFocus = function($cell) {
  this.$el.find('.shift-record').removeClass('focus');
  $cell.addClass('focus');
};

Gws_Affair_ShiftRecords.prototype.onClickCell = function($cell) {
  this.setFocus($cell);

  var day = $cell.data('day');
  var user = $cell.data('user');

  var showsToolbar = false;
  var editable = this.options.editable;
  if (editable) {
    var url = this.options.shiftRecordUrl;
    url = url.replace(':day', day);
    url = url.replace(':user', user);

    showsToolbar = true;
    this.$toolbar.find('.edit').attr('href', url).show();
  }

  if (! showsToolbar) {
    this.$toolbar.hide();
    return;
  }

  var offset = $cell.offset();
  if ($cell.hasClass('top')) {
    offset.top -= this.$toolbar.outerHeight();
  } else {
    offset.top += $cell.outerHeight();
  }

  // call `show` and then call `offset`. order is important
  this.$toolbar.show();
  this.$toolbar.offset(offset);
};



































SS.ready(function () {
  // external link
  $('a[href^=http]').not('[href*="' + location.hostname + '"]').attr({ target: '_blank', rel: "noopener" });

  // tabs
  var path = location.pathname + "/";
  $(".gws-schedule-tabs a").each(function () {
    var menu = $(this);
    if (path.match(new RegExp('^' + menu.attr('href') + '(/|$)'))) {
      menu.addClass("current");
    }
  });

  Gws_Member.render();
});
