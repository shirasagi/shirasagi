class @Cms_Editor_Module
  @editorId = "item_html"

  @getEditorHtml: (id = null) ->
    id ||= Cms_Form.editorId

    if (typeof tinymce != 'undefined')
      html = tinymce.get(id).getContent()
    else if (typeof CKEDITOR != 'undefined')
      html = CKEDITOR.instances[id].getData()
    else
      html = ""
    return html

  @setEditorHtml: (html, id = null)->
    id ||= Cms_Form.editorId

    if (typeof tinymce != 'undefined')
      tinymce.get(id).setContent(html)
    else if (typeof CKEDITOR != 'undefined')
      CKEDITOR.instances[id].setData(html)

class @Cms_Editor_CodeMirror
  # Render CodeMirror
  @render: (selector, opts = {}) ->
    $(selector).each ->
      form = $(this)
      cm = CodeMirror.fromTextArea form.get(0), opts
      cm.setSize null, form.height()
      cm.refresh() if opts["readonly"]
      form.data "editor", cm

  @lock: (selector, target) ->
    Cms_Editor_CodeMirror.setOption(selector, target)
    $(document).on 'change', selector, (e) ->
      Cms_Editor_CodeMirror.setOption(selector, target)

  @setOption: (selector, target) ->
    cm = $(target).next('.CodeMirror')[0].CodeMirror
    if $(selector).val() == ''
      cm.setOption 'mode', 'text/html'
      cm.setOption 'readOnly', false
    else
      cm.setOption 'mode', 'text/plain'
      cm.setOption 'readOnly', true

class @Cms_Editor_CKEditor
  # Render CKEditor
  @render: (selector, opts = {}) ->
    $(selector).ckeditor opts

    CKEDITOR.on 'dialogDefinition', (ev) ->
      name = ev.data.name
      def  = ev.data.definition
      if name == 'table' || name == 'tableProperties'
        info = def.getContents('info')
        text = info.get('txtWidth')
        text['default'] = ""
        text = info.get('txtCellSpace')
        text['controlStyle'] = "display: none"
        text['label'] = ""
        text['default'] = ""
        text = info.get('txtCellPad')
        text['controlStyle'] = "display: none"
        text['label'] = ""
        text['default'] = ""
        text = info.get('txtBorder')
        text['controlStyle'] = "display: none"
        text['label'] = ""
        text['default'] = ""
        text = info.get('txtSummary')
        text['controlStyle'] = "display: none"
        text['label'] = ""
        text['default'] = ""

class @Cms_Editor_TinyMCE
  # Render TinyMCE
  @render: (selector, opts = {}) ->
    opts["selector"] = selector
    tinymce.init opts
