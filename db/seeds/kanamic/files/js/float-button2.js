// フロートボタンの中身
$(document).ready(function () {
	$(".float-button2").append("<a href='https://www.kanamic.net/it-hojo/' onclick=\"ga('send', 'event', 'IT導入補助金_link', 'float-button2_click', 'https://www.kanamic.net/form/request/input.jsp', 1, {'nonInteraction': 1});\" target='_blank'>&nbsp;</a>");
});

$(window).load(function () {
	$(".float-button2").animate({
		marginBottom: "-5px"
	}, 500);
	
	//クリックイベントを設定する
	$(".float-button2").mouseover(function () {
		$(this).css("margin-bottom", "0");
	}).mouseout(function () {
		$(this).css("margin-bottom", "-5px");
	});
});


// 以下、スクロールでフェードイン用スクリプト

// グローバル変数
var syncerTimeout = null ;

// 一連の処理
$( function()
{
  // スクロールイベントの設定
  $( window ).scroll( function()
  {
    // 1秒ごとに処理
    if( syncerTimeout == null )
    {
      // セットタイムアウトを設定
      syncerTimeout = setTimeout( function(){

        // 対象のエレメント
        var element = $( '.top .float-button2' ) ;

        // 現在、表示されているか？
        var visible = element.is( ':visible' ) ;

        // 最上部から現在位置までの距離を取得して、変数[now]に格納
        var now = $( window ).scrollTop() ;

        // 最下部から現在位置までの距離を計算して、変数[under]に格納
        var under = $( 'body' ).height() - ( now + $(window).height() ) ;

        // 最上部から現在位置までの距離(now)が1px以上かつ
        // 最下部から現在位置までの距離(under)が200px以上かつ…
        if( now > 1 && 200 < under )
        {
          // 非表示状態だったら
          if( !visible )
          {
            // [.float-button2]をフェードインする
            element.fadeIn( 'fast' ) ;
          }
        }

        // 100px以下かつ
        // 表示状態だったら
        else if( visible )
        {
          // [.float-button2]をフェードアウトする
          element.fadeOut( 'fast' ) ;
        }

        // フラグを削除
        syncerTimeout = null ;
      } , 250 ) ;
    }
  } ) ;
  // クリックイベントを設定する
	/*
  $(".float-button2").mouseover(function(){
    $(this).css("margin-bottom","0");
  }).mouseout(function(){
    $(this).css("margin-bottom","-5px");
  });
	*/
});
