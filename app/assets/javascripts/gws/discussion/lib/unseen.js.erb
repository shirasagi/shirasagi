this.Gws_Discussion_Unseen = (function () {
  function Gws_Discussion_Unseen() {
  }

  Gws_Discussion_Unseen.url = null;

  Gws_Discussion_Unseen.intervalID = null;

  Gws_Discussion_Unseen.intervalTime = null;

  Gws_Discussion_Unseen.timestamp = null;

  Gws_Discussion_Unseen.renderUnseen = function (url, intervalTime, timestamp) {
    this.url = url;
    this.intervalTime = intervalTime;
    this.timestamp = timestamp;
    if (this.url && this.intervalTime && this.timestamp) {
      return this.intervalID = setInterval(this.checkMessage, this.intervalTime);
    }
  };

  Gws_Discussion_Unseen.checkMessage = function () {
    return $.ajax({
      url: Gws_Discussion_Unseen.url,
      success: function (data, status) {
        var timestamp;
        timestamp = parseInt(data);
        if (timestamp > Gws_Discussion_Unseen.timestamp) {
          $(".gws-discussion-unseen").show();
          return clearInterval(Gws_Discussion_Unseen.intervalID);
        }
      }
    });
  };

  return Gws_Discussion_Unseen;

})();
