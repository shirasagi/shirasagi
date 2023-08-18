$(function() {

//Page Top
  var pagetop = $(".pagetop");
  $(window).scroll(function () {
    var pagetop = $(".pagetop");
    if ($(this).scrollTop() > 100) {
      pagetop.fadeIn();
    } else {
      pagetop.fadeOut();
    }
  });
  pagetop.click(function () {
    $("body,html").animate({
      scrollTop: 0
    }, 500);
    return false;
  });

// ExternalIcon
  $("div#wrap a[href^='http'], #foot a[href^='http']").not("[href^='http://"+location.host+"'],[href^='https://"+location.host+"']").append(" <img src='/img/external.gif' alt='外部のサイトに移動します' title='外部のサイトに移動します' width='11' height='11' class='external' />");
  $("img + img.external").remove();

// current
  var path = location.pathname;
  $("#navi li").each(function() {
    var menu = $(this).find("a");
    if (path == menu.attr("href")) {
      return $(this).addClass("current");
    }
  });
  var url = location.pathname;
  var urlsprit = "/"+url.split("/")[1]+"/";
  $('#navi li a[href="'+urlsprit+'index.html"]').parent().addClass('current');
  $('#navi li a[href="'+urlsprit+'"]').parent().addClass('current');

// smartphone
  $(window).resize(function(){
    var w = $(window).width();
    if (w <= 768){
      $("#navi .wrap, #search").hide();
    } else {
      $("#navi .wrap, #search").show();
    }
  });
  $("#sp-btn .gmenu").click(function(e){
    $("#search").hide();
    $("#navi .wrap").slideToggle();
  });
  $("#sp-btn .search").click(function(e){
    $("#navi .wrap").hide();
    $("#search").slideToggle();
  });

  var w = $(window).width();
  var x = 768;
  if (w <= x) {
    $("table").wrap('<div class="wrap-table">...</div>');
  }else {
  }

});

