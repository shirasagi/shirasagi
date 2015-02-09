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

$(function(){
    $("#app-tab,#mypage-app-tab,#idea-tab,#mypage-idea-tab").each(function(){
        if(location.href.match(/^ouropendata\.jp$/i)) {
            $(this).attr("href", "#");
        }
    });
});

$(function(){
    $("#portal-app,#apps,#app-kv01,#app-kv02,#dataset-ideas,#portal-idea,#ideas,#idea-kv01,#idea-kv02").each(function(){
        if(location.href.match(/^ouropendata\.jp$/i)) {
            $(this).css("display", "none");
        }
    });
});
