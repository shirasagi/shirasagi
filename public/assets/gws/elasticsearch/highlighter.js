Gws_Elasticsearch_Highlighter = function () {
}

Gws_Elasticsearch_Highlighter.prototype = {
  render: function () {
    if (location.hash) {
      $(location.hash).css('border', '1px solid red');
    }
  }
}
;
