module SS::EditorHelper

  CODE_EXT_MODES = {
    html: :htmlmixed,
    scss: :css,
    js: :javascript,
    coffee: :coffeescript,
  }.freeze

  CODE_MODE_FILES = {
    htmlmixed: %w(xml javascript css vbscript htmlmixed),
  }.freeze

  def code_editor(elem, opts = {})
    mode   = opts[:mode].to_s.presence
    mode ||= opts[:filename].sub(/.*\./, "") if opts[:filename]

    mode = CODE_EXT_MODES[mode.to_sym] if mode && CODE_EXT_MODES[mode.to_sym]

    mode_path = "/assets/js/codemirror/mode"
    mode_file = "#{Rails.public_path}#{mode_path}"
    mode = nil if mode && !File.exists?("#{mode_file}/#{mode}/#{mode}.js")

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

  def html_editor_options(opts = {})
    case SS.config.cms.html_editor
    when "ckeditor"
      ckeditor_editor_options(opts)
    when "tinymce"
      tinymce_editor_options(opts)
    when "markdown"
      #html_editor_markdown(elem, opts)
    end
  end

  def ckeditor_editor_options(opts = {})
    opts = opts.symbolize_keys

    base_opts = SS.config.cms.ckeditor['options'].symbolize_keys
    if opts.delete(:readonly)
      readonly_options = SS.config.cms.ckeditor['readonly_options'].presence
      readonly_options ||= {}
      base_opts.merge!(readonly_options.symbolize_keys)
    end
    if opts.delete(:public_side)
      public_side_options = SS.config.cms.ckeditor['public_side_options'].presence
      public_side_options ||= {}
      base_opts.merge!(public_side_options.symbolize_keys)
    end
    if opts.delete(:advanced)
      advanced_options = SS.config.cms.ckeditor['advanced_options'].presence
      advanced_options ||= {}
      base_opts.merge!(advanced_options.symbolize_keys)
    end

    base_opts = site_ckeditor_editor_options(base_opts)

    opts.reverse_merge!(base_opts)
    opts[:extraPlugins] = opts[:extraPlugins].join(',') if opts[:extraPlugins].is_a?(Array)
    opts[:removePlugins] = opts[:removePlugins].join(',') if opts[:removePlugins].is_a?(Array)
    opts[:extraPlugins] ||= ''
    opts[:removePlugins] ||= ''

    if opts[:templates]
      opts[:templates_files] ||= []
      opts[:templates_files] << "#{template_cms_editor_templates_path}.js?_=#{Time.zone.now.to_i}"
    else
      opts.delete(:templates)
      opts.delete(:templates_files)
    end
    opts
  end

  def html_editor_ckeditor(elem, opts = {})
    SS.config.cms.ckeditor.fetch('stylesheets', []).each do |ss|
      controller.stylesheet ss
    end
    SS.config.cms.ckeditor.fetch('javascripts', []).each do |js|
      controller.javascript js
    end
    opts = ckeditor_editor_options(opts)
    jquery do
      "Cms_Editor_CKEditor.render('#{elem}', #{opts.to_json});".html_safe
    end
  end

  def tinymce_editor_options(opts = {})
    opts = opts.symbolize_keys

    base_opts = SS.config.cms.tinymce['options'].symbolize_keys
    if opts[:readonly]
      readonly_options = SS.config.cms.tinymce['readonly_options'].presence
      readonly_options ||= {}
      base_opts.merge!(readonly_options.symbolize_keys)
    elsif opts[:public_side]
      public_side_options = SS.config.cms.tinymce['public_side_options'].presence
      public_side_options ||= {}
      base_opts.merge!(public_side_options.symbolize_keys)
    else
      base_opts[:templates] = "#{template_cms_editor_templates_path}.json?_=#{Time.zone.now.to_i}"
    end

    base_opts = site_tinymce_editor_options(base_opts)
    base_opts[:plugins] ||= []

    opts.reverse_merge!(base_opts)
    opts
  end

  def html_editor_tinymce(elem, opts = {})
    controller.javascript "/assets/js/tinymce/tinymce.min.js"
    editor_opts = tinymce_editor_options(opts)
    jquery do
      "Cms_Editor_TinyMCE.render('#{elem}', #{editor_opts.to_json});".html_safe
    end
  end

  def html_editor_markdown(elem, opts = {})
  end

  def site_ckeditor_editor_options(opts = {})
    return opts if @cur_site.nil?
    if @cur_node
      color_button = @cur_node.try(:color_button) || @cur_site.color_button
      editor_css_path = @cur_node.try(:editor_css_path) || @cur_site.editor_css_path
    else
      color_button = @cur_site.color_button
      editor_css_path = @cur_site.editor_css_path
    end

    if color_button == 'enabled'
      opts[:extraPlugins] ||= ['colorbutton']
      opts[:removePlugins] ||= []
      opts[:removePlugins] -= ['colorbutton']
    end
    opts[:removePlugins] ||= ['colorbutton'] if color_button == 'disabled'

    opts[:contentsCss] ||= []
    opts[:contentsCss] += [editor_css_path] if editor_css_path.present?

    opts
  end

  def site_tinymce_editor_options(opts = {})
    return opts if @cur_site.nil?
    if @cur_node
      color_button = @cur_node.try(:color_button) || @cur_site.color_button
      editor_css_path = @cur_node.try(:editor_css_path) || @cur_site.editor_css_path
    else
      color_button = @cur_site.color_button
      editor_css_path = @cur_site.editor_css_path
    end

    if color_button == 'enabled'
      opts[:plugins] ||= []
      opts[:plugins].push('textcolor')
      opts[:plugins].uniq!
      if opts[:toolbar]
        opts[:toolbar] += ' | forecolor backcolor' unless opts[:toolbar].include?('forecolor backcolor')
      end
    end
    if color_button == 'disabled'
      opts[:plugins] ||= []
      opts[:plugins].delete('textcolor')
      if opts[:toolbar]
        opts[:toolbar].gsub!(' | forecolor backcolor', '')
      end
    end

    opts[:content_css] ||= []
    opts[:content_css] += [editor_css_path] if editor_css_path.present?

    opts
  end
end
