module EditorHelper
  def code_editor(elem, opts = {})
    mode = opts[:mode]
    if !mode && opts[:filename]
      extname = opts[:filename].sub(/.*\./, "")
      extname = "javascript" if extname == "js"
      mode = extname if File.exists?("#{Rails.public_path}/assets/js/ace/mode-#{extname}.js")
    end

    h  = []
    h << %(<script data-turbolinks-track="true" src="/assets/js/ace/mode-#{mode}.js"></script>) if mode
    h <<  coffee do
      j  = []
      j << %($ ->)
      j << %(  editor = $\("#{elem}"\).ace({ theme: "chrome", lang: "#{mode}" }))
      j << %(  ace = editor.data("ace").editor.ace)

      if opts[:readonly]
        j << %(  ace.setReadOnly(true))
        j << %(  h = ace.getSession().getScreenLength() * 16 + ace.renderer.scrollBar.getWidth())
        j << %(  $(ace["container"]).css("line-height", "16px"))
        j << %(  $(ace["container"]).height(h + "px"))
        j << %(  $(ace["container"]).find(".ace_scrollbar").hide())
      end

      j.join("\n").html_safe
    end

    h.join("\n").html_safe
  end

  def html_editor(elem, opts = {})
    if SS.config.cms.html_editor == "ckeditor"
      html_editor_ckeditor(elem, opts)
    elsif SS.config.cms.html_editor == "tinymce"
      html_editor_tinymce(elem, opts)
    elsif SS.config.cms.html_editor == "wiki"
      html_editor_wiki(elem, opts)
    end
  end

  def html_editor_ckeditor(elem, opts = {})
    opts = { extraPlugins: "", removePlugins: "" }.merge(opts)

    if opts[:readonly]
      opts[:removePlugins] << ",toolbar"
      #opts[:removePlugins] << ",resize"
      #opts[:extraPlugins]  << ",autogrow"
      opts[:readOnly] = true
      opts.delete :readonly
    end
    opts[:extraPlugins]  << ",templates,justify"
    #opts[:enterMode] = 2 #BR
    #opts[:shiftEnterMode] = 1 #P
    opts[:allowedContent] = true
    opts[:height] ||= "360px"

    h  = []
    h <<  coffee do
      j = []
      j << %($ ->)
      j << %(  $\("#{elem}"\).ckeditor #{opts.to_json})

      j << %(  CKEDITOR.on 'dialogDefinition', (ev) -> )
      j << %(    name = ev.data.name)
      j << %(    def  = ev.data.definition)
      j << %(    if name == 'table')
      j << %(      info = def.getContents('info'))
      j << %(      text = info.get('txtWidth'))
      j << %(      text['default'] = "")
      j << %(      text = info.get('txtCellSpace'))
      j << %(      text['controlStyle'] = "display: none")
      j << %(      text['label'] = "")
      j << %(      text['default'] = "")
      j << %(      text = info.get('txtCellPad'))
      j << %(      text['controlStyle'] = "display: none")
      j << %(      text['label'] = "")
      j << %(      text['default'] = "")
      j << %(      text = info.get('txtBorder'))
      j << %(      text['controlStyle'] = "display: none")
      j << %(      text['label'] = "")
      j << %(      text['default'] = "")
      j << %(      text = info.get('txtSummary'))
      j << %(      text['controlStyle'] = "display: none")
      j << %(      text['label'] = "")
      j << %(      text['default'] = "")

      j.join("\n").html_safe
    end

    h.join("\n").html_safe
  end

  def html_editor_tinymce(elem, opts = {})
    h  = []
    h <<  coffee do
      j = []
      j << %($ ->)
      j << %(  tinymce.init)
      j << %(    selector: "#{elem}")
      j << %(    language: "ja")

      if opts[:readonly]
      j << %(    readonly: true)
      j << %(    plugins: \[\])
      j << %(    toolbar: false)
      j << %(    menubar: false)
      #j << %(    statusbar: false)
      else
      j << %(    plugins: \[ )
      j << %(      "advlist autolink link image lists charmap print preview hr anchor pagebreak spellchecker",)
      j << %(      "searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking",)
      j << %(      "save table contextmenu directionality emoticons template paste textcolor")
      j << %(    \],)
      j << %(    toolbar: "insertfile undo redo | styleselect | bold italic | forecolor backcolor" +)
      j << %(      " | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image media")
      end

      j.join("\n").html_safe
    end

    h.join("\n").html_safe
  end

  def html_editor_wiki(elem, opts = {})
  end
end
