// JavaScript Document

$(function(){
 	var w = $(window).width();
		secondNav();
		
		searchTab();
		scrollCurrent()
		var floatNavH =	$('#floatNav').height();
		$('#floatNav').css("margin-top",-(floatNavH/2));
	//================================================================bodyのclassを取得して#gNavの.currentを設定
	$("body.care #gNav li.nav01").addClass("current");
	$("body.medical #gNav li.nav02").addClass("current");
	$("body.is-medical-page #gNav li.nav02").addClass("current");//2024/06 新ページのための応急措置
	$("body.child-care #gNav li.nav03").addClass("current");
	$("body.case #gNav li.navcase").addClass("current");
	$("body.company #gNav li.nav04").addClass("current");
	$("body.ir #gNav li.navir").addClass("current");
	$("body.recruit #gNav li.nav05").addClass("current");
	$("body.media_page #gNav li.nav04").addClass("current");
	$("body.topics #gNav li.nav04").addClass("current");
	$("body.event #gNav li.nav04").addClass("current");

	//================================================================ScrollでGnavにclass追加
	gNavHeight();
	$(window).scroll(function () {
		gNavHeight();
	});
	if($("body.top").length){
		slickerPC();
		$("#tabNews li").click(function(){
			thisNum = $(this).index();
			//$("#tabContent .block").css("visibility","hidden");
			//$("#tabContent .block").eq(thisNum).css("visibility","visible");
			$("#tabNews li").removeClass("current");
			$("#tabNews li").eq(thisNum).addClass("current");
			
			return false;
		});
	}
	
	//================================================================ScrollでGnavにclass追加
	function gNavHeight(){
		if ($(this).scrollTop() > 250) {
			$('header').addClass("small");
			$("#floatNav").addClass("appear");
		} else {
			$('header').removeClass("small");
			$("#floatNav").removeClass("appear");
		}
	}
	
	//================================================================セカンダリの挙動（640px以上の時のみ）
	function secondNav(){
		$("#gNav").css("display","block");
		var timer;
		var timerBG;
		var kakoIndex;
		var thisIndex;
		
		//gNav
		$("#gNav > ul > li").hover(function(){
			$(this).children("a").animate({'background-position-y': '-66px'},0);
			thisIndex = $(this).index();
			
			switch(thisIndex){
				case 3:
					return false;
				case 7:
					return false;
				case 6:
					return false;
			}
			
			//
			clearTimeout(timerBG);
			clearTimeout(timer);
			//
			//
			$("#secondMenu").css({"display":"block"});
			$("#secondMenu").transition({
				scale:(1,1),
				translate:0,
				perspective:"500px",
				rotateX:"0",
				opacity:1
			}).stop();
			
			switch(thisIndex){
				case 0:
					$("#secondMenu > ul").css({display:"none"});
					$("#secondMenu > ul").eq(0).css({display:"block"});
					$("#secondMenu > ul").eq(0).css({opacity:0});
					$("#secondMenu > ul").eq(0).transition({opacity:1}).stop();
				break;
				case 1:
					$("#secondMenu > ul").css({display:"none"});
					$("#secondMenu > ul").eq(1).css({display:"block"});
					$("#secondMenu > ul").eq(1).css({opacity:0});
					$("#secondMenu > ul").eq(1).transition({opacity:1}).stop();
				break;
				case 2:
					$("#secondMenu > ul").css({display:"none"});
					$("#secondMenu > ul").eq(2).css({display:"block"});
					$("#secondMenu > ul").eq(2).css({opacity:0});
					$("#secondMenu > ul").eq(2).transition({opacity:1}).stop();
				break;
				case 4:
					$("#secondMenu > ul").css({display:"none"});
					$("#secondMenu > ul").eq(3).css({display:"block"});
					$("#secondMenu > ul").eq(3).css({opacity:0});
					$("#secondMenu > ul").eq(3).transition({opacity:1}).stop();
				break;
				case 5:
					$("#secondMenu > ul").css({display:"none"});
					$("#secondMenu > ul").eq(4).css({display:"block"});
					$("#secondMenu > ul").eq(4).css({opacity:0});
					$("#secondMenu > ul").eq(4).transition({opacity:1}).stop();
				break;
				case 6:
					$("#secondMenu > ul").css({display:"none"});
					$("#secondMenu > ul").eq(5).css({display:"block"});
					$("#secondMenu > ul").eq(5).css({opacity:0});
					$("#secondMenu > ul").eq(5).transition({opacity:1}).stop();
				break;
			}
		},function(){
			//マウスアウトでカレント状態を戻す（.currentではなく背景位置の調整）
			$(this).children("a").animate({'background-position-y': '0'},0);
			$(this).children("li.current a").animate({'background-position-y': '-66px'},0);
			kakoIndex = thisIndex;
			timerBG = setTimeout(function(){
				$("#secondMenu").transition({
					scale:(0.8,0.8),
					translate:(0,"-10px"),
					perspective:"500px",
					rotateX:"-35deg",
					opacity:0
				}).stop();
				timer = setTimeout(function(){navElaser(kakoIndex)},500);
			},10);
		});
		
		$("#secondMenu").hover(function(){
			clearTimeout(timerBG);
			clearTimeout(timer);
			
			switch(thisIndex){
				case 0:
					$("#gNav > ul > li").children("a").eq(0).animate({'background-position-y': '-66px'},0);
				break;
				case 1:
					$("#gNav > ul > li").children("a").eq(1).animate({'background-position-y': '-66px'},0);
				break;
				case 2:
					$("#gNav > ul > li").children("a").eq(2).animate({'background-position-y': '-66px'},0);
				break;
				case 4:
					$("#gNav > ul > li").children("a").eq(4).animate({'background-position-y': '-66px'},0);
				break;
				case 5:
					$("#gNav > ul > li").children("a").eq(5).animate({'background-position-y': '-66px'},0);
				break;
				case 6:
					$("#gNav > ul > li").children("a").eq(6).animate({'background-position-y': '-66px'},0);
				break;
			}
		},function(){
			
			switch(thisIndex){
				case 0:
					if(!$("#gNav > ul > li").eq(thisIndex).hasClass("current")){
						$("#gNav > ul > li").eq(0).children("a").animate({'background-position-y': '0'},0);
					}
				break;
				case 1:
					if(!$("#gNav > ul > li").eq(thisIndex).hasClass("current")){
						$("#gNav > ul > li").eq(1).children("a").animate({'background-position-y': '0'},0);
					}
				break;
				case 2:
					if(!$("#gNav > ul > li").eq(thisIndex).hasClass("current")){
						$("#gNav > ul > li").eq(2).children("a").animate({'background-position-y': '0'},0);
					}
				break;
				case 4:
					if(!$("#gNav > ul > li").eq(thisIndex).hasClass("current")){
						$("#gNav > ul > li").eq(4).children("a").animate({'background-position-y': '0'},0);
					}
				break;
				case 5:
					if(!$("#gNav > ul > li").eq(thisIndex).hasClass("current")){
						$("#gNav > ul > li").eq(5).children("a").animate({'background-position-y': '0'},0);
					}
				break;
				case 6:
					if(!$("#gNav > ul > li").eq(thisIndex).hasClass("current")){
						$("#gNav > ul > li").eq(6).children("a").animate({'background-position-y': '0'},0);
					}
				break;
			}
			timerBG = setTimeout(function(){
				$("#secondMenu").transition({
					scale:(0.8,0.8),
					translate:(0,"-10px"),
					perspective:"500px",
					rotateX:"-35deg",
					opacity:0
				}).stop();
				timer = setTimeout(function(){navElaser(kakoIndex)},500);
			},10);
		});
			
			
	};
	
	//================================================================ナビからマウスを外したら、消えるように。
	function navElaser(num){
		$("#secondMenu").css({"display":"none"});
	};
	
	
	//================================================================TOPのSlick
	function slickerPC(){
		$('.newsScrollBox').slick({
		  dots: true,
		  infinite: false,
		  speed: 300,
		  slidesToShow: 4,
		  touchMove: false,
		  slidesToScroll: 4,
		  dots:false
		});
		var filtered02 = false;
		var filtered03 = false;
		var filtered04 = false;
		//tab01をクリックしたら全表示
		$('.tab01').on('click', function(){
			$('.newsScrollBox').slickUnfilter();
			filtered02 = false;
			filtered03 = false;
			filtered04 = false;
		});
		$('.tab02').on('click', function(){
			filtered03 = false;
			filtered04 = false;
			if(filtered02 === false) {
				$('.newsScrollBox').slickFilter('.kaigo');
				
				filtered02 = true;
			} else {
				$('.newsScrollBox').slickUnfilter();
				filtered02 = false;
			}
		});
		$('.tab03').on('click', function(){
			filtered02 = false;
			filtered04 = false;
			if(filtered03 === false) {
				$('.newsScrollBox').slickFilter('.iryo');
				
				filtered03 = true;
			} else {
				$('.newsScrollBox').slickUnfilter();
				filtered03 = false;
			}
		});
		$('.tab04').on('click', function(){
			filtered02 = false;
			filtered03 = false;
			if(filtered04 === false) {
				$('.newsScrollBox').slickFilter('.media');
				
				filtered04 = true;
			} else {
				$('.newsScrollBox').slickUnfilter();
				filtered04 = false;
			}
		});
	}
	
	//================================================================TOPの目的別
	//PC用
	
	function searchTab(){
		$("#search .block h4").click(function(){
			
			$("#search .block .list").css("display","none");
			var thisNum = $(this).parent().index();
			$("#search .block").eq(thisNum).children(".list").css("display","block");
			$("#search .block h4").removeClass("current");
			$(this).addClass("current");
			var listH = $("#search .block").eq(thisNum).children(".list").height();
			
			$("#search .bg").css("height",listH+300);//250 + tabContent 
			$("#search .bg").css("min-height",listH+300);//250 + tabContent 
		});
	}
	
	
	//下層ページ　スクロールイベント
	function scrollCurrent(){
		// ナビゲーションのリンクを指定
		var navLink = $('#floatNav li a');
	 
		// 各コンテンツのページ上部からの開始位置と終了位置を配列に格納しておく
		var contentsArr = new Array();
		for (var i = 0; i < navLink.length; i++) {
			// コンテンツのIDを取得
			var targetContents = navLink.eq(i).attr('href');
			// ページ内リンクでないナビゲーションが含まれている場合は除外する
			if(targetContents.charAt(0) == '#') {
				// ページ上部からコンテンツの開始位置までの距離を取得
				var targetContentsTop = $(targetContents).offset().top;
				// ページ上部からコンテンツの終了位置までの距離を取得
				var targetContentsBottom = targetContentsTop + $(targetContents).outerHeight(true) - 1;
				// 配列に格納
				contentsArr[i] = [targetContentsTop, targetContentsBottom]
			}
		};
	 
		// 現在地をチェックする
		function currentCheck() {
			// 現在のスクロール位置を取得
			var windowScrolltop = $(window).scrollTop()+50;
			for (var i = 0; i < contentsArr.length; i++) {
				// 現在のスクロール位置が、配列に格納した開始位置と終了位置の間にあるものを調べる
				if(contentsArr[i][0] <= windowScrolltop && contentsArr[i][1] >= windowScrolltop) {
					// 開始位置と終了位置の間にある場合、ナビゲーションにclass="current"をつける
					navLink.removeClass('current');
					navLink.eq(i).addClass('current');
					i == contentsArr.length;
				}
			};
		}
	 
		// ページ読み込み時とスクロール時に、現在地をチェックする
		$(window).on('load scroll', function() {
			currentCheck();
		});
	 
		// ナビゲーションをクリックした時のスムーズスクロール
		navLink.click(function() {
			$('html,body').animate({
				scrollTop: $($(this).attr('href')).offset().top
			}, 300);
			return false;
		})
	}
	
	//ipadの時のセカンダリ
	$(".close").click(function(){
		$("#secondMenu").transition({
				scale:(0.8,0.8),
				translate:(0,"-10px"),
				perspective:"500px",
				rotateX:"-35deg",
				opacity:0
			}).stop();
	});
	
	//PC SP共通
	if($("body.case").length){
		$("#lNav li a").click(function(){
			
			thisIndex = $(this).parent().index();
			$("#lNav li a").removeClass("current");
			$("#lNav li a").eq(thisIndex).addClass("current");
			$("#sec01").children("div").transition({opacity:0},500,function(){
				switch (thisIndex){
					case 0:
						$("#sec01").children("div").css({display:"block",opacity:0});
						$("#sec01").children("div").transition({opacity:1},500).stop();
					break;
					case 1:
						$("#sec01").children("div").css("display","none");
						$("#sec01").children("div.iryo").css({display:"block",opacity:0});
						$("#sec01").children("div.iryo").transition({opacity:1},500).stop();
					break;
					case 2:
						$("#sec01").children("div").css("display","none");
						$("#sec01").children("div.kaigo").css({display:"block",opacity:0});
						$("#sec01").children("div.kaigo").transition({opacity:1},500).stop();
					break;
					case 3:
						$("#sec01").children("div").css("display","none");
						$("#sec01").children("div.gyosei").css({display:"block",opacity:0});
						$("#sec01").children("div.gyosei").transition({opacity:1},500).stop();
					break;
				}
				
			}).stop();
			return false;
		});
	}
	
   // #で始まるアンカーをクリックした場合に処理
   $('a[href^=#]').click(function() {
      // スクロールの速度
      var speed = 400; // ミリ秒
      // アンカーの値取得
      var href= $(this).attr("href");
      // 移動先を取得
      var target = $(href == "#" || href == "" ? 'html' : href);
      // 移動先を数値で取得
      var position = target.offset().top;
      // スムーススクロール
      $('body,html').animate({scrollTop:position}, speed, 'linear');
      return false;
   });
   
   
});

