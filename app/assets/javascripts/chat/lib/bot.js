this.Chat_Bot = (function () {
  function Chat_Bot(id, url) {
    this.id = '#' + id;
    this.url = url;
    this.render();
  }

  Chat_Bot.prototype.render = function () {
    const _this = this;
    $(_this.id).find('.chat-button').click(function() {
      const text = $(this).prev('.chat-text').val();
      if(!text){
        return false;
      }
      $(_this.id).find('.chat-items').append($('<div class="chat-item user"></div>').append(text));
      $(this).prev('.chat-text').val('');
      $.ajax({
        type: "GET",
        url: _this.url,
        data: {
          text: text
        },
        success: function (res, status) {
          const result = $.parseJSON(res);
          if(result.text){
            $(_this.id).find('.chat-items').append($('<div class="chat-item sys"></div>').append(result.text));
          }
        },
        error: function (xhr, status, error) {
        }
      });
    });
  };

  return Chat_Bot;

})();

