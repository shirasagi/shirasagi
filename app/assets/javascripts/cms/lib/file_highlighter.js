Cms_File_Highlighter = function () {
}

Cms_File_Highlighter.prototype = {
  render: function () {
    if (location.hash) {
      $(location.hash).css('border', '1px solid red');
    }
  }
}
