$(document).ready(function() {
	$(".navi2 dt").hover(function(){
		$(this).css("cursor","pointer"); 
	},function(){
		$(this).css("cursor","default"); 
		});
	$(".navi2 dd").css("display","none");
	$(".navi2 dt").click(function(){
		$(this).next().slideToggle("fast");
		});
});