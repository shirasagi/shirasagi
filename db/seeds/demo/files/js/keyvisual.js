$(function(){
    var fadeTime = 1000;
	var delayTime = 5000;

	$('#slide-photo div').each(function(i){
		$(this).attr('id','view' + (i + 1).toString());
		$('#slide-photo div').css({zIndex:'98',opacity:'0'});
		$('#slide-photo div:first').css({zIndex:'99'}).stop().animate({opacity:'1'},fadeTime);
	});

	$('#slide-list span').click(function(){
		clearInterval(setTimer);

		var connectCont = $('#slide-list span').index(this);
		var showCont = connectCont+1;

		$('#slide-photo div#view' + (showCont)).siblings().stop().animate({opacity:'0'},fadeTime,function(){$(this).css({zIndex:'98'})});
		$('#slide-photo div#view' + (showCont)).stop().animate({opacity:'1'},fadeTime,function(){$(this).css({zIndex:'99'})});

		$(this).addClass('active');
		$(this).siblings().removeClass('active');
		$("#slide-list span img[src$='/img/s-button-on.gif']").each(function() {
			$(this).attr("src", "/img/s-button-off.gif");
		});
		$("#slide-list span.active img[src$='/img/s-button-off.gif']").each(function() {
			$(this).attr("src", "/img/s-button-on.gif");
		});

		timer();

	});

	$('#slide-list span:not(.active) img').hover(function(){
		$(this).attr("src",$(this).attr("src").replace("-off.", "-on."));
	},function(){
		$(this).attr("src",$(this).attr("src").replace("-on.", "-off."));
	});

	$('#slide-list span:first').addClass('active');
	$('#slide-list span.active img').attr("src", "/img/s-button-on.gif");

	timer();

	function timer() {
		setTimer = setInterval(function(){
			$('span.active').each(function(){
				var listLengh = $('#slide-list span').length;
				var listIndex = $('#slide-list span').index(this);
				var listCount = listIndex+1;

				if(listLengh == listCount){
					$('#slide-list span:first').click()
				} else {
					$(this).next('span').click();
				};
			});
		},delayTime);
	};

	$('#pause-play span.pause').click(function(){
		clearInterval(setTimer);
	});
	$('#pause-play span.play').click(function(){
		timer();
	});
});
