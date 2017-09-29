$(function() {
    $('.col3-flex li').mouseover(function(){
        $(this).find('img').css({transform:'scale(1.2)'})
        $(this).find('img').css({transition:'transform 0.5s'})
        $(this).find('img').toggleClass('filter');
    })
    $('.col3-flex li').mouseout(function(){
        $(this).find('img').toggleClass('filter');
        $(this).find('img').css({transform:'scale(1.0)'})
        $(this).find('img').css({transition:'transform 0.5s'})
    })
});
