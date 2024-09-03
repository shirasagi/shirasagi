/**
 * 共通JS common.js
 *
 */

/* ----------------------------------------------------------
 init
---------------------------------------------------------- */
// ready : 画像などが表示されるより前に実行
$(function () {

  // ヘッダー 注目ワードパーツの移動
  headerInsertKeywords();

  // ページトップボタンクリック時処理
  pagetopFunc();

  // サイドナビ：カレント表示
  currentDispFunc();

  // 特設サイト - サイドナビ：カレント表示
  specialCurrentDispFunc();

  // スマホメニュー処理 いらないかも
  // spmenuFunc();

  // スマホメニュー処理
  naviHoverFunc();

  // ハンバーガーメニュー開閉用
  hamburgerFunc();

  // TOPページSP時キービジュアルのページネーションを外に出す処理（htmlの移動）
  keyVisualMovePagination();

  // ？
  // externalIcon();

  // 新着タブにカテゴリーを表示（標準機能にないため）
  tabsCategoryFunc();

  // 記事ページ　ブロック処理用
  // docsPageBlockFunc();

  // 施設ページ　ブロック処理用
  // shisetsuPageBlockFunc();

  // ？
  // translateFunc();

  // ブロックリンク有効化
  // （カテゴリーリストのarticleをホバーすると配下のaタグに遷移するようにリンク領域を拡大）
  blockLinkFunc();

  // ？
  // chatFormUnfocusFunc();

  // ？
  // underTBFunc();

  // サイドメニューのライフイベントの一部メニュー項目にPC時のみ改行挿入
  // sidemenuLifeeventInsertBreakOnPc();

  // マイページ　チェックボックス見た目調整用タグ追加
  mypageCheckboxAddTags();

  // チャットボットのテキスト改行
  lineBreakChatbot();
});

// load : 画像などが表示された後に実行
$(window).load(function () {
  // Firefox対応

  // 新着タブの記事がない場合、RSSリンクを非表示にする
  invisibleNoinfoTabsRss();

  // チャットボット機能
  chatbotFunc();

  // 手続きガイド 結果ページアコーディオン機能
  guidesAccFunc();

  // 外部リンクアイコン追加
  addExternalIconFunc();

  // Gナビ：カレント表示
  gnaviCurrentFunc();

  // 便利なサービス：カレント表示
  serviceCurrentFunc();

  // // 入札トップ 表彰記事にカテゴリー名付与
  // addCatnameNyusatsuTopHyoushou();

  // youtube一覧ページ　高さ揃え
  youtubelistMatchHeight();

  // フロートメニューの位置切り替え
  floatMenuPositionerLoad();

  //イメージマップ
  imagemapFunc();

  // アンカーリンク自動生成
  addAnchorLinks();

  // ページ内アンカーリンクのスムーススクロール
  smoothScrollFunc();
});


/* ----------------------------------------------------------
 headerInsertKeywords
---------------------------------------------------------- */
var headerInsertKeywords = function () {
  $(".head-words").appendTo("#head .head__utility-downer");
}

/* ----------------------------------------------------------
 pagetopFunc
---------------------------------------------------------- */
var pagetopFunc = function () {
  var pagetop = $('.pagetop');
  pagetop.click(function () {
    $('body,html').animate({
      scrollTop: 0
    }, 500);
    return false;
  });
}

/* ----------------------------------------------------------
 currentDispFunc
---------------------------------------------------------- */
var currentDispFunc = function () {
  var path = location.pathname.replace(/\/index\.html$/, "/");
  $("#navi li").each(function () {
    var menu = $(this).find("a");
    if (path == menu.attr("href")) {
      $("this").addClass("current");
    }
  });
  var url = window.location.pathname;
  var url = "/" + url.split("/")[1] + "/";
  $('#navi li a[href="' + url + '"]').parent().addClass('current');
}

/* ----------------------------------------------------------
 specialCurrentDispFunc
---------------------------------------------------------- */
var specialCurrentDispFunc = function () {
  var path = location.pathname.replace(/\/index\.html$/, "/");
  $(".sub-catelist__list .sub-catelist__item").each(function () {
    var menu = $(this).find("a");
    var linkurl = menu.attr("href");
    if (path.indexOf(linkurl) >= 0) {
      $(this).addClass("current");
    }
  });
}

/* ----------------------------------------------------------
 spmenuFunc
---------------------------------------------------------- */
var spmenuFunc = function () {
  $("#menu-btn").click(function () {
    $(document.body).toggleClass("open");
    $(this).toggleClass("active");
    $('#gnavi').fadeToggle();
    return false;
  });

  $('#gnavi .gnavi-wrap-l ul > li span').click(function () {
    $(this).toggleClass("open");
    $(this).siblings().next('#gnavi .gnavi-wrap-l ul ul').slideToggle();
    //    $('#gnavi .gnavi-wrap-l ul > li span').not($(this)).siblings().next('#gnavi .gnavi-wrap-l ul ul').slideUp();
  });

  $('#gnavi li a').click(function () {
    $('#gnavi').hide();
    $(document.body).removeClass("open");
    $("#menu-btn").removeClass("active");
  });
}

/* ----------------------------------------------------------
 naviHoverFunc
---------------------------------------------------------- */
var naviHoverFunc = function () {
  $('#navi li.main-nav').hover(
    function () {
      $(this).addClass('hover');
      $(this).next().addClass('hover-next');
    },
    function () {
      $(this).removeClass('hover');
      $(this).next().removeClass('hover-next');
    }
  );
  $("#body--registration-reset_password-index #cat-mid-header h1").text("パスワードの変更")

}

/* ----------------------------------------------------------
 hamburgerFunc
---------------------------------------------------------- */
var hamburgerFunc = function () {
  $(".hamburger-menu__btn").click(function () {
    $(this).toggleClass('click-on');
    $(".hamburger-menu__btn + div").toggleClass('menu-on');
  });
}

/* ----------------------------------------------------------
 keyVisualMovePagination
---------------------------------------------------------- */
var keyVisualMovePagination = function () {
  $('.ss-swiper-slide swiper-container div .swiper-pagination').insertBefore('.ss-swiper-slide-controller');
}

/* ----------------------------------------------------------
 externalIcon
---------------------------------------------------------- */
var externalIcon = function () {
  $("#body--ijyu div#wrap #ijyu-recommend a[href^='http'], #body--index div#wrap a[href^='http'], div#addition a[href^='http']").not("[href^='http://" + location.host + "'],[href^='https://" + location.host + "']").append(" <img src='https://www.city.mima.lg.jp/gyosei/img/external.svg' alt='外部のサイトに移動します' title='外部のサイトに移動します' width='16' height='16' class='external' />");
  $("#img.external").remove();

  $("div#wrap a[href^='http'], div#addition a[href^='http']").not("[href^='http://" + location.host + "'],[href^='https://" + location.host + "']").append(" <img src='https://www.city.mima.lg.jp/gyosei/img/external-g.svg' alt='外部のサイトに移動します' title='外部のサイトに移動します' width='16' height='16' class='external external-g' />");
  $("#img.external").remove();
  $('#page a[href^="http"]').not("[href^='http://" + location.host + "'],[href^='https://" + location.host + "']").attr('target', '_blank');

}

/* ----------------------------------------------------------
 docsPageBlockFunc
---------------------------------------------------------- */
var docsPageBlockFunc = function () {
  $('footer.contact').children(':not(h2)').wrapAll('<div class="contact-detail"></div>');
  $('.contact-detail dl').wrapAll('<div class="contact-telfax"></div>');
  //  $('.page .related-pages h2').html('このページと<br />関連性の高いページ');
  //  $(".page .related-pages").appendTo(".page .sub-info");
}

/* ----------------------------------------------------------
 shisetsuPageBlockFunc
---------------------------------------------------------- */
var shisetsuPageBlockFunc = function () {
  $('.map .yield-wrap .condition dt.category').text('施設の種類');
  $('.map .yield-wrap .condition dt.service').text('施設の用途');
  $('.map .yield-wrap .condition dt.location').text('施設の地域');
  $('.map .yield-wrap .settings .ajax-box').html('検索条件を<br />変更する');
  $('<div class="link-btn"><a href="#">現在地から施設を探す</a></div>').insertAfter('.map .yield-wrap nav.filters');

}

/* ----------------------------------------------------------
 translateFunc
---------------------------------------------------------- */
var translateFunc = function () {
  //  $(window).on('load resize', function(){
  //   var w = $(window).width();
  $('#translate-wrap').insertAfter('#tool .tools #lang');
  $('#translate-wrap').show();
  //  });
}

/* ----------------------------------------------------------
 blockLinkFunc
---------------------------------------------------------- */
var blockLinkFunc = function () {
  $(".category-nodes article, .cms-nodes article, .ezine-pages li").click(function () {
    window.location = $(this).find("a").attr("href");
    return false;
  });
}

// /* ----------------------------------------------------------
//  chatFunc
// ---------------------------------------------------------- */
// var chatFunc = function () {
//   $('.chat-close').click(function () {
//     $('.chat-close').hide();
//     $('.chat-open').show();
//   });
//   $('.chat-open .close-btn').click(function () {
//     $('.chat-open').hide();
//     $('.chat-close').show();
//   });

//   // $('.guide-nodes .guide-lists h2').click(function () {
//   //   $(this).next().slideToggle();
//   //   $(this).toggleClass('toggle-arrow');
//   // });
//   // $('.guide-nodes .guide-lists .close-btn').click(function () {
//   //   $(this).parent().slideToggle();
//   //   $(this).toggleClass('toggle-arrow');
//   // });
// }


/* ----------------------------------------------------------
 chatFormUnfocusFunc
---------------------------------------------------------- */
var chatFormUnfocusFunc = function () {
  $('.chat-items').on('scroll', function () {
    var active_element = document.activeElement;
    if (active_element) {
      active_element.blur();
    }
  });
}

/* ----------------------------------------------------------
 underTBFunc
---------------------------------------------------------- */
var underTBFunc = function () {
  $(window).on('load resize', function () {
    var w = $(window).width();
    if (w > 768) {
      $('#wrap .cms-site-search form+select#target').insertAfter('#wrap .cms-site-search form .site-search-keyword');
    } else {
      $('#wrap .cms-site-search form select#target').insertAfter('#wrap .cms-site-search form');
    }
  });
}

/* ----------------------------------------------------------
 tabsCategoryFunc
---------------------------------------------------------- */
var tabsCategoryFunc = function () {
  // 新着情報以外のタブについて処理
  $('.cms-tabs .tab:nth-child(n+2)').each(function () {
    var catName = $('h2', this).text();
    var catId = $(this).attr('id');
    $('time', this).after('<span class="cat ' + catId + '">' + catName + '</span>');

    var tabCont = $(this).html();

    // 新着情報タブ内に自分のタブ内の記事があればカテゴリータグを追加
    $('.cms-tabs .tab:first-child h3').each(function () {
      var link = $('a', this).attr('href');
      if (tabCont.indexOf(link) !== -1) {
        //$(this).prev('span.cat').remove();
        $(this).prev('time').after('<span class="cat ' + catId + '">' + catName + '</span>');
      }
    });
  });

  $('.cms-tabs article').each(function () {
    var label = $('h2', this).text();
    $('a.more', this).text('お知らせ一覧を見る');
  });
  $('.cms-tabs article').each(function () {
    var label = $('h2', this).text();
    $('a.more', this).text($('a.more', this).parents('article').find('h2').text() + '一覧を見る');
  });
}

/* ----------------------------------------------------------
 invisibleNoinfoTabsRss
---------------------------------------------------------- */
var invisibleNoinfoTabsRss = function () {
  $(window).on('load', function () {
    $(".tabs .view .no-info").parent().next("nav").css({
      'display': 'none'
    });
  });
  // $(".tabs .view .no-info").parent().next("nav").css({
  //   'display': 'none'
  // });
}

/* ----------------------------------------------------------
 chatbotFunc
---------------------------------------------------------- */
var chatbotFunc = function () {
  $('.chat--close').click(function () {
    $('.chat--close').hide();
    $('.chat--open').show();
  });
  $('.chat--open .close-btn ').click(function () {
    $('.chat--open').hide();
    $('.chat--close').show();
  });
  $('.chat-form   .chat-dismiss ').click(function () {
    $('.chat--open').hide();
    $('.chat--close').show();
  });
}

/* ----------------------------------------------------------
 guidesAccFunc
---------------------------------------------------------- */
var guidesAccFunc = function () {
  $('.guide-nodes .guide__lists .procedure__wrap').hide();
  $('.guide-nodes .guide__lists h2').click(function () {
    $(this).next().slideToggle();
    $(this).toggleClass('click--on');
  });
  $('.guide-nodes .guide__lists .close-btn').click(function () {
    $(this).parent().slideToggle();
    $(this).toggleClass('click--on');
  });

  // $('.guide-nodes .guide-lists h2').click(function () {
  //   $(this).next().slideToggle();
  //   $(this).toggleClass('toggle-arrow');
  // });
  // $('.guide-nodes .guide-lists .close-btn').click(function () {
  //   $(this).parent().slideToggle();
  //   $(this).parent().prev().toggleClass('toggle-arrow');
  // });
}

/* ----------------------------------------------------------
 addExternalIconFunc
---------------------------------------------------------- */
var addExternalIconFunc = function () {
  $(window).on('load', function () {
    // ExternalIcon
    $("#body--ijyu div#wrap #ijyu-recommend a[href^='http'], #body--index div#wrap a[href^='http'], div#addition a[href^='http']").not("[href^='http://" + location.host + "'],[href^='https://" + location.host + "']").append(" <img src='/img/external.png' alt='外部のサイトに移動します' title='外部のサイトに移動します' width='16' height='16' class='external' />");
    $("#img.external").remove();

    $("div#wrap a[href^='http'], div#addition a[href^='http']").not("[href^='http://" + location.host + "'],[href^='https://" + location.host + "']").append(" <img src='/img/external-g.png' alt='外部のサイトに移動します' title='外部のサイトに移動します' width='16' height='16' class='external external-g' />");
    $("#img.external").remove();
    $('#page a[href^="http"]').not("[href^='http://" + location.host + "'],[href^='https://" + location.host + "']").attr('target', '_blank');

  });
}

/* ----------------------------------------------------------
 gnaviCurrentFunc
---------------------------------------------------------- */
var gnaviCurrentFunc = function () {
  $('#navi .cat-mainnavi__item a.cat-mainnavi__link').each(function () {
    var target = $(this).attr('href');
    if (location.href.match(target)) {
      $(this).parents('.cat-mainnavi__item').addClass('current');
    } else {
      $(this).parents('.cat-mainnavi__item').removeClass('current');
    }
  });
}

/* ----------------------------------------------------------
 serviceCurrentFunc
---------------------------------------------------------- */
var serviceCurrentFunc = function () {
  $('.mod-menu--service .mod-menu__item a.mod-menu__link').each(function () {
    var target = $(this).attr('href');
    if (location.href.match(target)) {
      $(this).parent().addClass('current');
    } else {
      $(this).parent().removeClass('current');
    }
  });
}

/* ----------------------------------------------------------
 addCatnameNyusatsuTopHyoushou
---------------------------------------------------------- */
var addCatnameNyusatsuTopHyoushou = function () {
  $('#body--nyusatsu-index #main .oshirase-docs__list .item-hyoushou a').each(function () {
    var tmptext = $(this).text();
    $(this).text("【美馬市優良工事表彰】" + tmptext);
  });
}

/* ----------------------------------------------------------
 youtubelistMatchHeight
---------------------------------------------------------- */
var youtubelistMatchHeight = function () {
  if (document.URL.match(/youtube/)) {
    $(window).on('load resize', function () {
      var w = $(window).width();
      if (w > 480) {
        $('#body--youtube-index .youtube .youtube__movie-wrap h2').matchHeight();
      }
    });
  }
}

/* ----------------------------------------------------------
 floatMenuPositionerLoad
---------------------------------------------------------- */
var floatMenuPositionerLoad = function () {
  var floatMenuPositioner = function () {
    if (windowHeight < (headerHeight + 30 + floatHeight)) {
      // ウィンドウの高さが低い場合
      $("body").addClass("low-height");

      if (scrollTop >= (documentHeight - (floatHeight + footHeight + 30) - 30)) {
        // フッターが見える場合
        $("body").addClass("visible-footer");
      } else {
        // フッターが見えない場合
        $("body").removeClass("visible-footer");

        if ((headerHeight + 30 + floatHeight) + 30 - scrollTop <= windowHeight) {
          // フロートメニューが見える場合
          $("body").addClass("visible-float");
        } else {
          // フロートメニューが見えない場合
          $("body").removeClass("visible-float");
        }

      }
    } else {
      // ウィンドウの高さが高い場合
      $("body").removeClass("low-height");

      if (documentHeight - scrollPosition <= footHeight) {
        // フッターが見える場合
        $("body").addClass("visible-footer");
      } else {
        // フッターが見えない場合
        $("body").removeClass("visible-footer");
      }
    }

    if (scrollTop < headerHeight) {
      // Gナビメニューが見える場合
      $("body").addClass("visible-navi");
    } else {
      // Gナビメニューが見えない場合
      $("body").removeClass("visible-navi");
    }
  }

  var headerHeight = $(".accessibility").outerHeight() + $("#head").outerHeight() + $("#navi").outerHeight();
  var floatHeight = $(".float__list").height() + 10 + $("#chat").height();
  var documentHeight = $(document).height();
  var windowHeight = $(window).height();
  var scrollTop = $(window).scrollTop();
  var scrollPosition = windowHeight + $(window).scrollTop() - 30;
  var footHeight = $("footer").outerHeight() - $(".footer__image").outerHeight() + 30;

  floatMenuPositioner();

  $(window).on('resize scroll', function () {
    headerHeight = $(".accessibility").outerHeight() + $("#head").outerHeight() + $("#navi").outerHeight();
    floatHeight = $(".float__list").height() + 10 + $("#chat").height();
    documentHeight = $(document).height();
    windowHeight = $(window).height();
    scrollTop = $(window).scrollTop();
    scrollPosition = windowHeight + $(window).scrollTop() - 30;
    footHeight = $("footer").outerHeight() - $(".footer__image").outerHeight() + 30;

    floatMenuPositioner();
  });
}

/* ----------------------------------------------------------
 sidemenuLifeeventInsertBreakOnPc
---------------------------------------------------------- */
var sidemenuLifeeventInsertBreakOnPc = function () {

  $(window).on('load resize', function () {
    var w = $(window).width();
    if (w > 768) {
      $('.mod-menu.mod-menu--lifeevent .mod-menu__item--sumai .mod-menu__menu-name').html("<div class='mod-menu__menu-name'>引越・<br>住まい</div>");
      $('.mod-menu.mod-menu--lifeevent .mod-menu__item--byoki .mod-menu__menu-name').html("<div class='mod-menu__menu-name'>病気・<br>障がい</div>");
    } else {
      $('.mod-menu.mod-menu--lifeevent .mod-menu__item--sumai .mod-menu__menu-name').html("<div class='mod-menu__menu-name'>引越・住まい</div>");
      $('.mod-menu.mod-menu--lifeevent .mod-menu__item--byoki .mod-menu__menu-name').html("<div class='mod-menu__menu-name'>病気・障がい</div>");
    }
  });
}

/* ----------------------------------------------------------
 mypageCheckboxAddTags
---------------------------------------------------------- */
var mypageCheckboxAddTags = function () {

  if (document.URL.match(/gyosei\/mypage\/profile\/edit/) || document.URL.match(/gyosei\/mypage\/first-registration/)) {
    $('form .column label').each(function () {
      if ($(this).find('input') != undefined) {
        var text = $(this).text();
        var input = $(this).find('input').prop("outerHTML");
        $(this).text("");
        $(this).append(input);
        $(this).append('<span>' + text + '</span>');

      }
    });
  }
}

/* ----------------------------------------------------------
 lineBreakChatbot
---------------------------------------------------------- */

var lineBreakChatbot = function () {
  $('#chat .chat--close p').html('<p>なんでも<br>聞いてね！</p>');
}

/* ----------------------------------------------------------
 imagemapFunc
---------------------------------------------------------- */
var imagemapFunc = function () {
  if (document.URL.match(/gyosei\/shiosainomori\/construction\//)) {
    $('.image-map-pages img[usemap]').rwdImageMaps();

    $(window).on('load resize', function () {
      $('.image-map-pages .area-contents').addClass("mfp-hide").addClass("area-contents--initialized");
      $('.colors-on-map').remove();
      $(".image-map-pages").append('<div class="colors-on-map">');

      var colorCnt = 1;
      $('map[name*="image-map-"] area').each(function () {
        var itemCoordinateArray = $(this).attr("coords").split(',');
        var itemPositionLeft = Number(itemCoordinateArray[0]);
        var itemPositionTop = Number(itemCoordinateArray[1]);
        var itemWidth = Number(itemCoordinateArray[2]) - Number(itemCoordinateArray[0]);
        var itemHeight = Number(itemCoordinateArray[3]) - Number(itemCoordinateArray[1]);
        var itemState = $(this).data('state');
        $(".colors-on-map").append('<div id="color' + colorCnt + '" class="color-frame color-frame--' + itemState + '">');
        $("#color" + colorCnt).css({
          'content': "",
          'position': "absolute",
          'width': itemWidth,
          'height': itemHeight
        }).css({
          'top': itemPositionTop,
          'left': itemPositionLeft
        });
        colorCnt++;
      });
    });

    $('.image-map-pages map area[href^="#"]:not([data-state="completed"])').magnificPopup({
      type: 'inline',
      preloader: false
    });

    var w = $(window).width();
    var x = 768;
    if (w <= x) {
      $("table").wrap('<div class="wrap-table" />');
    } else {}
  }
}

/* ----------------------------------------------------------
 addAnchorLinks
---------------------------------------------------------- */
var addAnchorLinks = function () {
  if (window.document.body.id === 'body--organization-index') {
    if ($('#anchor-links-wrap').length) {
      $('#anchor-links-wrap').append('<nav class="anchor-links"><h2 class="anchor-links__header">ページ内目次</h2><ul class="anchor-links__list"></ul></nav>');
      $('.yield-wrap h2').each(function () {
        var id = $(this).attr('id');
        var title = $(this).text();
        $('ul.anchor-links__list').append('<li class="anchor-links__item"><a href="#' + id + '">' + title + '</a></li>');
      })
    }
  }
}

/* ----------------------------------------------------------
 smoothScrollFunc
---------------------------------------------------------- */
var smoothScrollFunc = function () {
  $('#main a[href^="#"]').click(function () {
    // 移動先
    var adjust = 0;
    // スクロール速度
    var speed = 400;
    // アンカーの値取得
    var href = $(this).attr("href");
    // 移動先取得
    var target = $(href == "#" || href == "" ? 'html' : href);
    // 移動先調整
    var position = target.offset().top + adjust;
    // スムーススクロール
    $('body,html').animate({
      scrollTop: position
    }, speed, 'swing');
    return false;
  });
}
