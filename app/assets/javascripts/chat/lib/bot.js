this.Chat_Bot = (function () {
  function Chat_Bot(id, url) {
    this.id = '#' + id;
    this.url = url;
    this.clickSuggest = false;
    this.render();
  }

  Chat_Bot.prototype.render = function () {
    var _this = this;
    $(_this.id).find('.chat-text').keypress(function (ev) {
      if ((ev.which && ev.which === 13) || (ev.keyCode && ev.keyCode === 13)) {
        _this.sendText($(this));
      }
    });
    $(_this.id).find('.chat-button').click(function() {
      _this.sendText($(this));
    });
    $(_this.id).find('.chat-items').click(function(e) {
      if ($(e.target).hasClass('chat-suggest')) {
        _this.clickSuggest = true;
        $(_this.id).find('.chat-text').val($(e.target).text());
        _this.sendText($(this));
        return false;
      } else if ($(e.target).hasClass('chat-success')) {
        _this.sendSuccess($(e.target));
      }  else if ($(e.target).hasClass('chat-retry')) {
        _this.sendRetry($(e.target));
      }
    });
  };

  Chat_Bot.prototype.firstText = function (el) {
    var _this = this;
    $.ajax({
      type: "GET",
      url: this.url,
      cache: false,
      data: {
        click_suggest: this.clickSuggest
      },
      success: function (res, status) {
        var result = res;
        if (typeof res === 'string' || res instanceof String) {
          result = $.parseJSON(res);
        }
        $.each(result.results, function (i, r) {
          if(r.response){
            if(r.suggests){
              el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item sys"></div>').append(r.response));
              r.suggests.forEach(function(suggest) {
                var chatSuggest = $('<a class="chat-suggest"></a>').attr('href', _this.url).append(suggest);
                el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item suggest"></div>').append(chatSuggest));
              });
            } else {
              el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item sys"></div>').append(r.response));
            }
            el.parents('.chat-part').find('.chat-items').animate({ scrollTop: el.parents('.chat-part').find('.chat-items')[0].scrollHeight });
          }
        });
        el.parents('.chat-part').find('.chat-text').focus();
      },
      error: function (xhr, status, error) {
      }
    });
  };

  Chat_Bot.prototype.sendText = function (el) {
    var _this = this;
    var text = el.parents('.chat-part').find('.chat-text').val();
    if(!text){
      return false;
    }
    el.parents('.chat-part').find('.chat-text').blur();
    $(this.id).find('.chat-items').append($('<div class="chat-item user"></div>').append(text));
    el.parents('.chat-part').find('.chat-items').animate({ scrollTop: el.parents('.chat-part').find('.chat-items')[0].scrollHeight });
    el.parents('.chat-part').find('.chat-text').val('');
    $.ajax({
      type: "GET",
      url: this.url,
      cache: false,
      data: {
        text: text,
        click_suggest: this.clickSuggest
      },
      success: function (res, status) {
        var result = res;
        if (typeof res === 'string' || res instanceof String) {
          result = $.parseJSON(res);
        }
        $.each(result.results, function (i, r) {
          if(r.response){
            if(r.siteSearchUrl) {
              var siteSearchLink = $('<a href="' + r.siteSearchUrl + '" target="_blank"></a>').append(result.siteSearchText);
              var siteSearchParagraph = $('<p class="search-result-btn"></p>').append(siteSearchLink);
            } else {
              var siteSearchParagraph = '';
            }
            if(r.suggests){
              el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item sys"></div>').append(r.response).append(siteSearchParagraph));
              r.suggests.forEach(function(suggest) {
                var chatSuggest = $('<a class="chat-suggest"></a>').attr('href', _this.url).append(suggest);
                el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item suggest"></div>').append(chatSuggest));
              });
            } else if(r.question) {
              var chatSuccess = $('<button name="button" type="button" class="chat-success" data-id="' + r.id + '"></button>').append(result.chatSuccess);
              var chatRetry = $('<button name="button" type="button" class="chat-retry" data-id="' + r.id + '"></button>').append(result.chatRetry);
              var chatFinish = $('<div class="chat-finish"></div>').append(r.question).append(chatSuccess).append(chatRetry);
              el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item sys"></div>').append(r.response).append(siteSearchParagraph).append(chatFinish));
            } else {
              el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item sys"></div>').append(r.response).append(siteSearchParagraph));
            }
            el.parents('.chat-part').find('.chat-items').animate({ scrollTop: el.parents('.chat-part').find('.chat-items')[0].scrollHeight });
          }
        });
        el.parents('.chat-part').find('.chat-text').focus();
      },
      error: function (xhr, status, error) {
      }
    });
  };

  Chat_Bot.prototype.sendSuccess = function (el) {
    var _this = this;
    $.ajax({
      type: "GET",
      url: this.url,
      cache: false,
      data: {
        intent_id: el.attr('data-id'),
        question: 'success'
      },
      success: function (res, status) {
        var result = res;
        if (typeof res === 'string' || res instanceof String) {
          result = $.parseJSON(res);
        }
        $.each(result.results, function (i, r) {
          if(r.response){
            el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item sys"></div>').append(r.response));
            el.parents('.chat-part').find('.chat-items').animate({ scrollTop: el.parents('.chat-part').find('.chat-items')[0].scrollHeight });
          }
        });
        setTimeout(function () { _this.firstText(el.parents('.chat-part').find('.chat-items')) }, 1000)
      },
      error: function (xhr, status, error) {
      }
    });
  };

  Chat_Bot.prototype.sendRetry = function (el) {
    var _this = this;
    $.ajax({
      type: "GET",
      url: this.url,
      cache: false,
      data: {
        intent_id: el.attr('data-id'),
        question: 'retry'
      },
      success: function (res, status) {
        var result = res;
        if (typeof res === 'string' || res instanceof String) {
          result = $.parseJSON(res);
        }
        $.each(result.results, function (i, r) {
          if(r.response){
            el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item sys"></div>').append(r.response));
            el.parents('.chat-part').find('.chat-items').animate({ scrollTop: el.parents('.chat-part').find('.chat-items')[0].scrollHeight });
          }
        });
        setTimeout(function () { _this.firstText(el.parents('.chat-part').find('.chat-items')) }, 1000)
      },
      error: function (xhr, status, error) {
      }
    });
  };

  return Chat_Bot;

})();

