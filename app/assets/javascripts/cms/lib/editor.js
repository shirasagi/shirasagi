this.Cms_Editor_Module = (function () {
  function Cms_Editor_Module() {
  }

  Cms_Editor_Module.editorId = "item_html";

  Cms_Editor_Module.getEditorHtml = function (id) {
    var html;
    if (id == null) {
      id = null;
    }
    id || (id = Cms_Form.editorId);
    if (typeof tinymce !== 'undefined') {
      html = tinymce.get(id).getContent();
    } else if (typeof CKEDITOR !== 'undefined') {
      html = CKEDITOR.instances[id].getData();
    } else {
      html = "";
    }
    return html;
  };

  Cms_Editor_Module.setEditorHtml = function (html, opts) {
    var id = null;

    opts = opts || {};
    if (opts["id"]) {
      id = opts["id"];
    }

    id || (id = Cms_Form.editorId);
    if (typeof tinymce !== 'undefined') {
      return tinymce.get(id).setContent(html);
    } else if (typeof CKEDITOR !== 'undefined') {
      return CKEDITOR.instances[id].setData(html);
    }
  };

  return Cms_Editor_Module;

})();

this.Cms_Editor_CodeMirror = (function () {
  function Cms_Editor_CodeMirror() {
    //Render codeMirror
  }

  Cms_Editor_CodeMirror.render = function (selector, opts) {
    if (opts == null) {
      opts = {};
    }
    return $(selector).each(function () {
      var cm, form;
      form = $(this);
      cm = CodeMirror.fromTextArea(form.get(0), opts);
      cm.setSize(null, form.height());
      if (opts["readonly"]) {
        cm.refresh();
      }
      return form.data("editor", cm);
    });
  };

  Cms_Editor_CodeMirror.lock = function (selector, target) {
    Cms_Editor_CodeMirror.setOption(selector, target);
    return $(document).on('change', selector, function (_ev) {
      return Cms_Editor_CodeMirror.setOption(selector, target);
    });
  };

  Cms_Editor_CodeMirror.setOption = function (selector, target) {
    var cm;
    cm = $(target).next('.CodeMirror')[0].CodeMirror;
    if ($(selector).val() === '') {
      cm.setOption('mode', 'text/html');
      return cm.setOption('readOnly', false);
    } else {
      cm.setOption('mode', 'text/plain');
      return cm.setOption('readOnly', true);
    }
  };

  return Cms_Editor_CodeMirror;

})();

this.Cms_Editor_CKEditor = (function () {
  function Cms_Editor_CKEditor() {
  }

  var onceInitialized = false;

  Cms_Editor_CKEditor.initializeOnce = function () {
    if (onceInitialized) {
      return;
    }

    onceInitialized = true;

    CKEDITOR.on('dialogDefinition', function (ev) {
      var def, info, name, text;
      name = ev.data.name;
      def = ev.data.definition;
      if (name === 'table' || name === 'tableProperties') {
        info = def.getContents('info');
        text = info.get('txtWidth');
        text['default'] = "";
        text = info.get('txtCellSpace');
        text['controlStyle'] = "display: none";
        text['label'] = "";
        text['default'] = "";
        text = info.get('txtCellPad');
        text['controlStyle'] = "display: none";
        text['label'] = "";
        text['default'] = "";
        text = info.get('txtBorder');
        text['controlStyle'] = "display: none";
        text['label'] = "";
        text['default'] = "";
        text = info.get('txtSummary');
        text['controlStyle'] = "display: none";
        text['label'] = "";
        return text['default'] = "";
      }
    });

    // fix. CKEditor Paste Dialog: github.com/ckeditor/ckeditor4/issues/469
    CKEDITOR.on('instanceReady', function (outerEv) {
      var elemet = outerEv.editor.element.$;
      outerEv.editor.on("change", function () {
        var event = new CustomEvent("ss:change", { bubbles: true, cancelable: true, composed: true });
        elemet.dispatchEvent(event);
      });
      outerEv.editor.on("beforeCommandExec", function(innerEv) {
        // Show the paste dialog for the paste buttons and right-click paste
        if (innerEv.data.name === "paste") {
          innerEv.editor._.forcePasteDialog = true;
        }
        // Don't show the paste dialog for Ctrl+Shift+V
        if (innerEv.data.name === "pastetext" && innerEv.data.commandData.from === "keystrokeHandler") {
          innerEv.cancel();
        }
      });
    });
  }

  Cms_Editor_CKEditor.render = function (selector, opts, _jsOpts) {
    //Render CKEditor
    if (opts == null) {
      opts = {};
    }

    // $(selector).ckeditor(opts);
    $(selector).each(function() {
      var $this = $(this);
      SS.justOnce(this, "ss-editor", function() {
        $this.ckeditor(opts);
      });
    });

    Cms_Editor_CKEditor.initializeOnce();
  };

  Cms_Editor_CKEditor.destroy = function (selector) {
    $(selector).each(function() {
      var $this = $(this);
      var editor = $this.data("ckeditorInstance");
      if (editor) {
        editor.destroy();
      }

      SS.deleteJustOnce(this, "ss-editor");
    });
  };

  return Cms_Editor_CKEditor;

})();

this.Cms_Editor_TinyMCE = (function () {
  function Cms_Editor_TinyMCE() {
  }

  Cms_Editor_TinyMCE.render = function (selector, opts) {
    //Render TinyMCE
    if (opts == null) {
      opts = {};
    }
    opts["selector"] = selector;
    return tinymce.init(opts);
  };

  return Cms_Editor_TinyMCE;

})();
