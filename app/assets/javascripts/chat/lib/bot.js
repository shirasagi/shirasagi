this.Chat_Bot = (function () {
  function Chat_Bot(id, url) {
    this.id = '#' + id;
    this.url = url;
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
        $(_this.id).find('.chat-text').val($(e.target).text());
        _this.sendText($(this));
        return false;
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
      data: {
        text: text
      },
      success: function (res, status) {
        var result = $.parseJSON(res);
        if(result.text){
          el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item sys"></div>').append(result.text));
          if(result.suggest){
            result.suggest.forEach(function(suggest) {
              var chatSuggest = $('<a class="chat-suggest"></a>').attr('href', _this.url).append(suggest);
              el.parents('.chat-part').find('.chat-items').append($('<div class="chat-item suggest"></div>').append(chatSuggest));
            });
          }
          el.parents('.chat-part').find('.chat-items').animate({ scrollTop: el.parents('.chat-part').find('.chat-items')[0].scrollHeight });
        }
        el.parents('.chat-part').find('.chat-text').focus();
      },
      error: function (xhr, status, error) {
      }
    });
  };

  return Chat_Bot;

})();

