module SS::EditorHelper

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

    controller.stylesheet "/assets/css/codemirror/codemirror.css"
    controller.javascript "/assets/js/codemirror/codemirror.js"

    if mode
      (CODE_MODE_FILES[mode.to_sym] || [mode]).each do |m|
        controller.javascript "#{mode_path}/#{m}/#{m}.js"
      end
    end

    editor_opts = {}
    editor_opts[:mode]        = mode if mode.present?
    editor_opts[:readOnly]    = true if opts[:readonly]
    editor_opts[:lineNumbers] = true

    jquery do
      "Cms_Editor_CodeMirror.render('#{elem}', #{editor_opts.to_json});".html_safe
    end
  end

  def html_editor(elem, opts = {})
    case SS.config.cms.html_editor
    when "ckeditor"
      html_editor_ckeditor(elem, opts)
    when "tinymce"
      html_editor_tinymce(elem, opts)
    when "markdown"
      html_editor_markdown(elem, opts)
    end
  end

  def html_editor_ckeditor(elem, opts = {})
    controller.javascript "/assets/js/ckeditor/ckeditor.js"
    controller.javascript "/assets/js/ckeditor/adapters/jquery.js"

    opts = { extraPlugins: "", removePlugins: "" }.merge(opts)

    if opts[:readonly]
      opts[:removePlugins] << ",toolbar"
      #opts[:removePlugins] << ",resize"
      #opts[:extraPlugins] << ",autogrow"
      opts[:readOnly] = true
      opts.delete :readonly
    end
    opts[:extraPlugins] << ",templates,justify"
    #opts[:enterMode] = 2 #BR
    #opts[:shiftEnterMode] = 1 #P
    opts[:allowedContent] = true
    opts[:height] ||= "360px"

    opts[:templates] = 'shirasagi'
    opts[:templates_files] = [ "#{template_cms_editor_templates_path}.js?_=#{Time.zone.now.to_i}" ]

    jquery do
      "Cms_Editor_CKEditor.render('#{elem}', #{opts.to_json});".html_safe
    end
  end

  def html_editor_tinymce(elem, opts = {})
    controller.javascript "/assets/js/tinymce/tinymce.min.js"

    editor_opts = {}
    editor_opts[:selector] = elem
    editor_opts[:language] = "ja"

    if opts[:readonly]
      editor_opts[:readonly] = true
      editor_opts[:plugins]  = []
      editor_opts[:toolbar]  = false
      editor_opts[:menubar]  = false
    else
      editor_opts[:plugins] = [
        "advlist autolink link image lists charmap print preview hr anchor pagebreak spellchecker",
        "searchreplace wordcount visualblocks visualchars code fullscreen insertdatetime media nonbreaking",
        "save table contextmenu directionality emoticons template paste textcolor"
      ]
      editor_opts[:toolbar] = "insertfile undo redo | styleselect | bold italic | forecolor backcolor" \
        " | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image media"

      # editor_opts[:templates] = [ { title: 'Some title 1', description: 'Some desc 1', content: 'My content' } ]
      editor_opts[:templates] = "#{template_cms_editor_templates_path}.json?_=#{Time.zone.now.to_i}"
    end

    jquery do
      "Cms_Editor_TinyMCE.render('#{elem}', #{editor_opts.to_json});".html_safe
    end
  end

  def html_editor_markdown(elem, opts = {})
  end
end
