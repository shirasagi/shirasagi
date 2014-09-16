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
  $("div#wrap a[href^='http'], div#addition a[href^='http']").not("[href^='http://"+location.host+"'],[href^='https://"+location.host+"']").append(" <img src='/img/external.gif' alt='外部のサイトに移動します' title='外部のサイトに移動します' width='16' height='16' class='external' />");
  $("#img.external").remove();

// current
  var path = location.pathname;
  $("#gnav li").each(function() {
    var menu = $(this).find("a");
    if (path == menu.attr("href")) {
      return $(this).addClass("current");
    }
  });
  var url = location.pathname;
  var urlsprit = "/"+url.split("/")[1]+"/";
  $('#gnav li a[href="'+urlsprit+'index.html"]').parent().addClass('current');


  $("#side-menu .cms-pages").each(function() {
    var menu = $(this).find("a");
    if (path == menu.attr("href")) {
      return $(this).addClass("current");
    }
    $("#side-menu li").each(function() {
      var menu = $(this).find("a");
      if (path == menu.attr("href")) {
        return $(this).parents(".pages").addClass("current");
      }
    });
    $("#side-menu li").each(function() {
      var menu = $(this).find("a");
      if (path == menu.attr("href")) {
        return $(this).addClass("current");
      }
    });
  });

  var path2 = location.pathname;
  $(".cms-pages .cms-pages").each(function() {
    var menu = $(this).find("a");
    if (path2 == menu.attr("href")) {
      return $(this).addClass("current");
    }
  });

// block link
  $("#wrap").on('click', '#product article, .product article', function(){
    location.href = $(this).find("a").attr("href");
    return false;
  });
// smartphone
  var w = $(window).width();
  var x = 600;
  if (w <= x) {
    $("#search form, #gnav ul").hide();
    $('#search h2, #gnav h2').click(function(e){
      $('+form, +ul',this).slideToggle();
      $("#search h2, #gnav h2").toggleClass("open");
    });
    $('#search h2').click(function(e){
      $("#gnav ul").hide();
      $("#gnav h2").removeClass("open");
    });
    $('#gnav h2').click(function(e){
      $("#search form").hide();
      $("#search h2").removeClass("open");
    });
  }else {
    $("#search form, #gnav ul").show();
  }

});

