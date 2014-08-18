# coding: utf-8
module EditorHelper
  def code_editor(elem, opts = {})
    mode = opts[:mode]
    if !mode && opts[:filename]
      extname = opts[:filename].sub(/.*\./, "")
      extname = "javascript" if extname == "js"
      mode = extname if File.exists?("#{Rails.public_path}/assets/js/ace/mode-#{extname}.js")
    end

    h  = []
    h << %Q[<script data-turbolinks-track="true" src="/assets/js/ace/mode-#{mode}.js"></script>] if mode
    h <<  coffee do
      j  = []
      j << %Q[$ ->]
      j << %Q[  editor = $("#{elem}").ace({ theme: "chrome", lang: "#{mode}" })]
      j << %Q[  ace = editor.data("ace").editor.ace]

      if opts[:readonly]
        j << %Q[  ace.setReadOnly(true)]
        j << %Q[  h = ace.getSession().getScreenLength() * 16 + ace.renderer.scrollBar.getWidth()]
        j << %Q[  $(ace["container"]).css("line-height", "16px")]
        j << %Q[  $(ace["container"]).height(h + "px")]
        j << %Q[  $(ace["container"]).find(".ace_scrollbar").hide()]
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
      j << %Q[$ ->]
      j << %Q[  $("#{elem}").ckeditor #{opts.to_json}]

      j << %Q[  CKEDITOR.on 'dialogDefinition', (ev) -> ]
      j << %Q[    name = ev.data.name]
      j << %Q[    def  = ev.data.definition]
      j << %Q[    if name == 'table']
      j << %Q[      info = def.getContents('info')]
      j << %Q[      text = info.get('txtWidth')]
      j << %Q[      text['default'] = ""]
      j << %Q[      text = info.get('txtCellSpace')]
      j << %Q[      text['controlStyle'] = "display: none"]
      j << %Q[      text['label'] = ""]
      j << %Q[      text['default'] = ""]
      j << %Q[      text = info.get('txtCellPad')]
      j << %Q[      text['controlStyle'] = "display: none"]
      j << %Q[      text['label'] = ""]
      j << %Q[      text['default'] = ""]
      j << %Q[      text = info.get('txtBorder')]
      j << %Q[      text['controlStyle'] = "display: none"]
      j << %Q[      text['label'] = ""]
      j << %Q[      text['default'] = ""]
      j << %Q[      text = info.get('txtSummary')]
      j << %Q[      text['controlStyle'] = "display: none"]
      j << %Q[      text['label'] = ""]
      j << %Q[      text['default'] = ""]

      j.join("\n").html_safe
    end

    h.join("\n").html_safe
  end

  def html_editor_tinymce(elem, opts = {})
    h  = []
    h <<  coffee do
      j = []
      j << %Q[$ ->]
      j << %Q[  tinymce.init]
      j << %Q[    selector: "#{elem}"]
      j << %Q[    language: "ja"]

      if opts[:readonly]
      j << %Q[    readonly: true]
      j << %Q[    plugins: \[\]]
      j << %Q[    toolbar: false]
      j << %Q[    menubar: false]
      #j << %Q[    statusbar: false]
      else
      j << %Q[    plugins: \[ ]
      j << %Q[      "advlist autolink link image lists charmap print preview hr anchor pagebreak spellchecker",]
      j << %Q[      "searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking",]
      j << %Q[      "save table contextmenu directionality emoticons template paste textcolor"]
      j << %Q[    \],]
      j << %Q[    toolbar: "insertfile undo redo | styleselect | bold italic | forecolor backcolor" +]
      j << %Q[      " | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image media"]
      end

      j.join("\n").html_safe
    end

    h.join("\n").html_safe
  end

  def html_editor_wiki(elem, opts = {})
  end
end
