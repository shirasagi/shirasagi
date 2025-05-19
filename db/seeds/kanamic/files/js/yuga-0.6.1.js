/*
 * yuga.js 0.6.1 - 優雅なWeb制作のためのJS
 *
 * Copyright (c) 2007 Kyosuke Nakamura (kyosuke.jp)
 * Licensed under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 *
 * Since:     2006-10-30
 * Modified:  2008-05-29
 *
 * jQuery 1.2.6
 * ThickBox 3.1
 */

/*
 * [使用方法] XHTMLのhead要素内で次のように読み込みます。
 
<link rel="stylesheet" href="css/thickbox.css" type="text/css" media="screen" />
<script type="text/javascript" src="js/jquery.js"></script>
<script type="text/javascript" src="js/thickbox.js"></script>
<script type="text/javascript" src="js/yuga.js" charset="utf-8"></script>

 */

(function($) {

	$(function() {
		$.yuga.selflink();
		$.yuga.rollover();
		//$.yuga.externalLink();
		//$.yuga.thickbox();
		$.yuga.scroll();
		//$.yuga.tab();
		//$.yuga.stripe();
		//$.yuga.css3class();
	});

	//---------------------------------------------------------------------

	$.yuga = {
		// URIを解析したオブジェクトを返すfunction
		Uri: function(path){
			this.originalPath = path;
			//絶対パスを取得
			this.absolutePath = (function(){
				var a = document.createElement('a');
				a.href = path;
				return a.href;
			})();
			//絶対パスを分解
			var fields = {'schema' : 2, 'username' : 5, 'password' : 6, 'host' : 7, 'path' : 9, 'query' : 10, 'fragment' : 11};
			var r = /^((\w+):)?(\/\/)?((\w+):?(\w+)?@)?([^\/\?:]+):?(\d+)?(\/?[^\?#]+)?\??([^#]+)?#?(\w*)/.exec(this.absolutePath);
			for (var field in fields) {
				this[field] = r[fields[field]]; 
			}
		},
		//現在のページと親ディレクトリへのリンク
		selflink: function (options) {
			var c = $.extend({
				hoverClass:'btn',
				selfLinkClass:'current',
				parentsLinkClass:'parentsLink',
				postfix: '_cr'
			}, options);
			$('a[href]').each(function(){
				var href = new $.yuga.Uri(this.getAttribute('href'));
				var setImgFlg = false;
				if ((href.absolutePath == location.href) && !href.fragment) {
					//同じ文書にリンク
					$(this).addClass(c.selfLinkClass);
					setImgFlg = true;
				} else if (0 <= location.href.search(href.absolutePath)) {
					//親ディレクトリリンク
					$(this).addClass(c.parentsLinkClass);
					setImgFlg = true;
				}
				if (setImgFlg){
					//img要素が含まれていたら現在用画像（_cr）に設定
					$(this).find('img:not(#kLogo)').each(function(){
						//ロールオーバークラスが設定されていたら削除
						$(this).removeClass(c.hoverClass);
						this.originalSrc = $(this).attr('src');
						this.currentSrc = this.originalSrc.replace(/(\.gif|\.jpg|\.png)/, c.postfix+"$1");
						$(this).attr('src',this.currentSrc);
					});
				}
			});
		},
		//ロールオーバー
		rollover: function(options) {
			var c = $.extend({
				hoverSelector: '.btn',
				groupSelector: '.btngroup',
				postfix: '_on'
			}, options);
			//ロールオーバーするノードの初期化
			$(c.hoverSelector).each(function(){
				this.originalSrc = $(this).attr('src');
				this.rolloverSrc = this.originalSrc.replace(/(\.gif|\.jpg|\.png)$/, c.postfix+"$1");
				this.rolloverImg = new Image;
				this.rolloverImg.src = this.rolloverSrc;
			});
			//通常ロールオーバー
			var inGroup = new Array();
			$.each(c.groupSelector.split(/,\s?/), function(i, n){
				inGroup.push(n + ' ' + c.hoverSelector.replace(/,\s?/, ', '+ n +' '));
			})
			$(c.hoverSelector).not($(inGroup.join(', '))).hover(function(){
				$(this).attr('src',this.rolloverSrc);
			},function(){
				$(this).attr('src',this.originalSrc);
			});
			//グループ化されたロールオーバー
			$(c.groupSelector).hover(function(){
				$(this).find(c.hoverSelector).each(function(){
					$(this).attr('src',this.rolloverSrc);
				});
			},function(){
				$(this).find(c.hoverSelector).each(function(){
					$(this).attr('src',this.originalSrc);
				});
			});
		},
		//外部リンクは別ウインドウを設定
		externalLink: function(options) {
			var c = $.extend({
				windowOpen:true,
				externalClass: 'externalLink'
			}, options);
			var e = $('a[href^="http://"]');
			if (c.windowOpen) {
				e.click(function(){
					window.open(this.href, '_blank');
					return false;
				});
			}
			e.addClass(c.externalClass);
		},
		//画像へ直リンクするとthickboxで表示(thickbox.js利用)
		thickbox: function() {
			try {
				tb_init('a[@href$=".jpg"], a[@href$=".gif"], a[@href$=".png"]');
			} catch(e) {
			}	
		},
		//ページ内リンクはするするスクロール
		scroll: function(options) {
			//ドキュメントのスクロールを制御するオブジェクト
			var scroller = (function() {
				var c = $.extend({
					easing:100,
					step:30,
					fps:60
				}, options);
				c.ms = Math.floor(1000/c.fps);
				var timerId;
				var param = {
					stepCount:0,
					startY:0,
					endY:0,
					lastY:0
				};
				//スクロール中に実行されるfunction
				function move() {
					if (param.stepCount == c.step) {
						//スクロール終了時
						window.scrollTo(getCurrentX(), param.endY);
					} else if (param.lastY == getCurrentY()) {
						//通常スクロール時
						param.stepCount++;
						window.scrollTo(getCurrentX(), getEasingY());
						param.lastY = getEasingY();
						timerId = setTimeout(move, c.ms); 
					}
				}
				function getCurrentY() {
					return document.body.scrollTop  || document.documentElement.scrollTop;
				}
				function getCurrentX() {
					return document.body.scrollLeft  || document.documentElement.scrollLeft;
				}
				function getEasingY() {
					return Math.floor(getEasing(param.startY, param.endY, param.stepCount, c.step, c.easing));
				}
				function getEasing(start, end, stepCount, step, easing) {
					var s = stepCount / step;
					return (end - start) * (s + easing / (100 * Math.PI) * Math.sin(Math.PI * s)) + start;
				}
				return {
					set: function(options) {
						this.stop();
						if (options.startY == undefined) options.startY = getCurrentY();
						param = $.extend(param, options);
						param.lastY = param.startY;
						timerId = setTimeout(move, c.ms); 
					},
					stop: function(){
						clearTimeout(timerId);
						param.stepCount = 0;
					}
				};
			})();
			$('a[href^=#], area[href^=#]').not('a[href=#], area[href=#]').each(function(){
				this.hrefdata = new $.yuga.Uri(this.getAttribute('href'));
			}).click(function(){
				var target = $('#'+this.hrefdata.fragment);
				if (target.length) {
					scroller.set({
						endY: target.offset().top
					});
					return false;
				}
			});
		},
		//タブ機能
		tab: function(options) {
			var c = $.extend({
				tabNavSelector:'.tabNav',
				activeTabClass:'active'
			}, options);
			$(c.tabNavSelector).each(function(){
				var tabNavList = $(this).find('a[href^=#], area[href^=#]');
				var tabBodyList;
				tabNavList.each(function(){
					this.hrefdata = new $.yuga.Uri(this.getAttribute('href'));
					var selecter = '#'+this.hrefdata.fragment;
					if (tabBodyList) {
						tabBodyList = tabBodyList.add(selecter);
					} else {
						tabBodyList = $(selecter);
					}
					$(this).unbind('click');
					$(this).click(function(){
						tabNavList.removeClass(c.activeTabClass);
						$(this).addClass(c.activeTabClass);
						tabBodyList.hide();
						$(selecter).show();
						return false;
					});
				});
				tabBodyList.hide()
				tabNavList.filter(':first').trigger('click');
			});
		},
		//奇数、偶数を自動追加
		stripe: function(options) {
			var c = $.extend({
				oddClass:'odd',
				evenClass:'even'
			}, options);
			$('ul, ol').each(function(){
				//JSでは0から数えるのでevenとaddを逆に指定
				$(this).children('li:odd').addClass(c.evenClass);
				$(this).children('li:even').addClass(c.oddClass);
			});
			$('table').each(function(){
				$(this).children('tr:odd').addClass(c.evenClass);
				$(this).children('tr:even').addClass(c.oddClass);
			});
		},
		//css3のクラスを追加
		css3class: function() {
			//:first-child, :last-childをクラスとして追加
			$('body :first-child').addClass('firstChild');
			$('body :last-child').addClass('lastChild');
			//css3の:emptyをクラスとして追加
			$('body :empty').addClass('empty');
		}
	};
})(jQuery);
