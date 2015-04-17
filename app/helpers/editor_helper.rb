module EditorHelper

  CODE_EXT_MODES = {
    html: :htmlmixed,
    scss: :css,
    js: :javascript,
    coffee: :coffeescript,
  }

  CODE_MODE_FILES = {
    htmlmixed: %w(xml javascript css vbscript htmlmixed),
  }

  def code_editor(elem, opts = {})
    mode   = opts[:mode].to_s.presence
    mode ||= opts[:filename].sub(/.*\./, "") if opts[:filename]

    mode = CODE_EXT_MODES[mode.to_sym] if mode && CODE_EXT_MODES[mode.to_sym]

    mode_path = "/assets/js/codemirror/mode"
    mode_file = "#{Rails.public_path}#{mode_path}"
    mode = nil unless File.exists?("#{mode_file}/#{mode}/#{mode}.js") if mode

    h  = []

    if mode
      (CODE_MODE_FILES[mode.to_sym] || [mode]).each do |m|
        h << %(<script data-turbolinks-track="true" src="#{mode_path}/#{m}/#{m}.js"></script>)
      end
    end

    h <<  jquery do
      editor_opts = {}
      editor_opts[:mode]        = mode if mode.present?
      editor_opts[:readOnly]    = true if opts[:readonly]
      editor_opts[:lineNumbers] = true

      "Cms_Editor_CodeMirror.render('#{elem}', #{editor_opts.to_json});".html_safe
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

    jquery do
      "Cms_Editor_CKEditor.render('#{elem}', #{opts.to_json});".html_safe
    end
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
