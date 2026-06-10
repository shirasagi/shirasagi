this.Cms_Loop_Snippet = (function () {
  function Cms_Loop_Snippet() {
  }

  // ループHTML設定のスニペットセレクターを初期化する。
  //
  // options:
  //   addon          : アドオンのコンテナセレクター (例: "#addon-...")
  //   textarea       : スニペットを挿入する CodeMirror の textarea セレクター
  //   templateSelect : テンプレート選択用の <select> セレクター (任意)
  Cms_Loop_Snippet.render = function (options) {
    options = options || {};

    var $snippetSelect = $(options.addon).find('.loop-snippet-selector');
    if ($snippetSelect.length === 0) {
      return;
    }

    var $textarea = options.textarea ? $(options.textarea) : $();
    var $templateSelect = options.templateSelect ? $(options.templateSelect) : $();

    // スニペットセレクターの初期値を「直接入力」に設定
    if (!$snippetSelect.val()) {
      $snippetSelect.val('');
    }

    // テンプレート選択中はスニペットを挿入しても editor が readOnly のため反映されない。
    // 操作不能であることを明示するためセレクター自体を disabled にする。
    var syncDisabled = function () {
      $snippetSelect.prop('disabled', !!$templateSelect.val());
    };
    syncDisabled();
    $templateSelect.on('change', syncDisabled);

    // スニペットの選択処理: CodeMirror のカーソル位置/選択範囲に挿入
    $snippetSelect.on('change', function () {
      var snippet = $snippetSelect.find(':selected').data('snippet');
      $snippetSelect.val('');
      if (!snippet) {
        return;
      }
      if ($textarea.length === 0) {
        return;
      }
      var editor = $textarea.data('editor');
      if (!editor) {
        return;
      }
      editor.getDoc().replaceSelection(snippet);
      editor.focus();
      editor.save();
    });
  };

  return Cms_Loop_Snippet;

})();
