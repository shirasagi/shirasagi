$(function() {

//Page Top
  var pagetop = $('.pagetop');
  $(window).scroll(function () {
    var pagetop = $('.pagetop');
    if ($(this).scrollTop() > 100) {
      pagetop.fadeIn();
    } else {
      pagetop.fadeOut();
    }
  });
  pagetop.click(function () {
    $('body,html').animate({
      scrollTop: 0
    }, 500);
    return false;
  });

// ExternalIcon
  $("div#wrap a[href^='http'], div#addition a[href^='http']").not("[href^='http://"+location.host+"'],[href^='https://"+location.host+"']").append(" <img src='/img/external.png' alt='外部のサイトに移動します' title='外部のサイトに移動します' width='16' height='16' class='external' />");
  $("#img.external").remove();

// current
  var path = location.pathname.replace(/\/index\.html$/, "/");
  $("#navi li").each(function() {
    var menu = $(this).find("a");
    if (path == menu.attr("href")) {
      $("this").addClass("current");
    }
  });
  var url = "/"+window.location.pathname.split("/")[1]+"/";
  $('#navi li a[href="'+url+'"]').parent().addClass('current');

// navi
  var w = $(window).width();
  var x = 600;
  if (x <= w) {
    $("#navi li").hover(function() {
      $(this).children('ul').show();
      $(this).children('a').addClass("current");
    }, function() {
      $(this).children('ul').hide();
      $(this).children('a').removeClass("current");
    });
  }
  var agent = navigator.userAgent;
  if(agent.match(/(iPhone|iPad|Android)/)){
    $('#navi li').children('ul').remove();
  }

// block link
  $(".category-nodes article").click(function(){
    window.location=$(this).find("a").attr("href");
    return false;
  });

});
