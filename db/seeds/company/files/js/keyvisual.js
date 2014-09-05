// keyvisual
jQuery(function(){
  jQuery('#camera_wrap_1').camera({
    height: '300px',
    thumbnail: false,
    pagination: true
  });
});
$(function() {
  var kvsc = $("#keyvisual").offset().top;
  $("#keyvisual .cameraSlide").css("margin-top", -10 + "px");
  $(window).scroll(function() {
    var value = $(this).scrollTop();
    $("#keyvisual .cameraSlide").css("margin-top", kvsc - 20 + value / 2);
  });
});
