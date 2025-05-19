// JavaScript Document

$(function(){
	
	
    var agent = navigator.userAgent;
 	var w = $(window).width();


	//===================================スマホユーザーの場合のみViewportを640に設定===================================
	/*
	var view640 = '<meta name="viewport" content="width=640">';
	var view960 = '<meta name="viewport" content="width=1000">';
    if(agent.search(/iPhone/) != -1 || agent.search(/iPod/) != -1 || agent.search(/Android/) != -1){
		$("meta:last").after(view640);
	}else{
		$("meta:last").after(view960);
	}
	*/
	//===================================androidユーザーの場合のみ発動===================================
    if(agent.search(/Android/) != -1){
		$("html").addClass("android");
	}
	//===================================スマホユーザーの場合のみ発動===================================
	smartNav();
	
	//TOP
	if($("body.top").length){
		slickerSP();
		searchTabSp()
	}
		
		
	//================================================================スマホの時のセカンダリの挙動
	function smartNav(){
		//
		$(".headerSp #menuSp").click(function(){
			$(this).toggleClass("open");
			$(".headerSp #gNav").toggle();
		});
		$(".headerSp #gNav > ul >li ul").css("display","none");
		$(".headerSp #gNav > ul >li ul").transition({
			scale:(1,1),
			translate:0,
			perspective:0,
			rotateX:"0deg",
			opacity:1
		})
		$(".headerSp #gNav > ul > li:has(span)").click(function(){
			$(this).children("ul").slideToggle();
			$(this).toggleClass("open");
		});
	}

	//================================================================セカンダリの挙動（640px以上の時のみ）
	//================================================================ナビからマウスを外したら、消えるように。
	
	
	//================================================================TOPのSlick
	function slickerSP(){
		$('.newsScrollBox').slick({
		  dots: true,
		  infinite: false,
		  speed: 300,
		  slidesToShow: 1,
		  touchMove: false,
		  slidesToScroll: 1,
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
	if($("body.top").length){
		//クリックしたら
		$("#tabNews li").click(function(){
			thisNum = $(this).index();
			//$("#tabContent .block").css("visibility","hidden");
			//$("#tabContent .block").eq(thisNum).css("visibility","visible");
			$("#tabNews li").removeClass("current");
			$("#tabNews li").eq(thisNum).addClass("current");
			
			return false;
		});
		
	}
	
	//================================================================TOPの目的別
	//スマホ用
	$("#search .block h4").removeClass("current");
	function searchTabSp(){
		$("#search .block h4").click(function(){
			
			$(this).next().slideToggle();
			$(this).toggleClass("current");
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
				console.log("target:",targetContentsTop)
				// ページ上部からコンテンツの終了位置までの距離を取得
				var targetContentsBottom = targetContentsTop + $(targetContents).outerHeight(true) - 1;
				// 配列に格納
				contentsArr[i] = [targetContentsTop, targetContentsBottom]
			}
		};
	 
		// 現在地をチェックする
		function currentCheck() {
			// 現在のスクロール位置を取得
			var windowScrolltop = $(window).scrollTop();
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
				scrollTop: $($(this).attr('href')).offset().top+10
			}, 300);
			return false;
		})
	}
	
	//PC SP共通
	if($("body.case").length){
		$("#lNav li a").click(function(){
			
			thisIndex = $(this).parent().index();
			$("#lNav li a").removeClass("current");
			$("#lNav li a").eq(thisIndex).addClass("current");
			$("#sec01").children("div").fadeOut("slow");
			switch (thisIndex){
				case 0:
					$("#sec01").children("div").fadeIn("slow");
				break;
				case 1:
					$("#sec01").children("div.iryo").fadeIn("slow");
				break;
				case 2:
					$("#sec01").children("div.kaigo").fadeIn("slow");
				break;
				case 3:
					$("#sec01").children("div.gyosei").fadeIn("slow");
				break;
			}
			
			return false;
		});
	}
});

