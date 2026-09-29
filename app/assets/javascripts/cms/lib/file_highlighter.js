globalThis.Cms_File_Highlighter = (function () {
  function Cms_File_Highlighter() {
  }

  Cms_File_Highlighter.prototype = {
    render: function () {
      if (location.hash) {
        $(location.hash).css('border', '1px solid red');
      }
    }
  }

  return Cms_File_Highlighter;
})();
