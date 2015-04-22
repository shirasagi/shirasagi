$(function(){
    $("#gnav li").each(function(){
        var menu = $(this).find("a");
        var $href = menu.attr("href");
        if(location.href.match($href)) {
        $(this).addClass('current');
        } else {
        $(this).removeClass('current');
        }
    });
});

$(function(){
    $("#mypage-tabs a").each(function(){
        var $href = $(this).attr("href");
        if(location.href.match($href)) {
        $(this).addClass('current');
        } else {
        $(this).removeClass('current');
        }
    });
});

$(function(){
    $(".detail nav a").each(function(){
        var $href = $(this).attr("href");
        if(location.href.match($href)) {
        $(this).addClass('current');
        } else {
        $(this).removeClass('current');
        }
    });
});

function showPlagin(idno){
    pc = ('PlagClose' + (idno));
    po = ('PlagOpen' + (idno));
    if( document.getElementById(pc).style.display == "none" ) {
      document.getElementById(pc).style.display = "block";
      document.getElementById(po).style.display = "none";
    }
    else {
      document.getElementById(pc).style.display = "none";
      document.getElementById(po).style.display = "block";
    }
}
