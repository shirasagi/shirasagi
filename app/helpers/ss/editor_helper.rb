module SS::EditorHelper

  CODE_EXT_MODES = {
    html: :htmlmixed,
    scss: :css,
    js: :javascript,
    coffee: :coffeescript
  }.freeze

  CODE_MODE_FILES = {
    htmlmixed: %w(xml javascript css vbscript htmlmixed).freeze
  }.freeze

  def code_editor_option(mode: nil, filename: nil, readonly: false)
    mode ||= filename.sub(/.*\./, "") if filename

    mode = CODE_EXT_MODES[mode.to_sym] if mode && CODE_EXT_MODES[mode.to_sym]

    mode_path = "/assets/js/codemirror/mode"
    mode_file = "#{Rails.public_path}#{mode_path}"
    mode = nil if mode && !File.exist?("#{mode_file}/#{mode}/#{mode}.js")

    controller.stylesheet "/assets/css/codemirror/codemirror.css"
    controller.javascript "/assets/js/codemirror/codemirror.js"

    if mode
      (CODE_MODE_FILES[mode.to_sym] || [mode]).each do |m|
        controller.javascript "#{mode_path}/#{m}/#{m}.js"
      end
    end

    editor_opts = {}
    editor_opts[:mode]        = mode if mode.present?
    editor_opts[:readOnly]    = true if readonly
    editor_opts[:lineNumbers] = true

    editor_opts
  end

  def code_editor(elem, delay_loads: nil, **opts)
    editor_opts = code_editor_option(**opts)
    scripts = []
    if delay_loads
      scripts << "SS_AddonTabs.findAddonView('#{delay_loads}').one('ss:addonShown', function() {"
      scripts << "  Cms_Editor_CodeMirror.render('#{elem}', #{editor_opts.to_json});".html_safe
      scripts << "});"
    else
      scripts << "Cms_Editor_CodeMirror.render('#{elem}', #{editor_opts.to_json});".html_safe
    end

    jquery do
      scripts.join("\n").html_safe
    end
  end

  def html_editor(elem, editor_opts = {}, js_opts = {})
    case SS.config.cms.html_editor
    when "ckeditor"
      html_editor_ckeditor(elem, editor_opts, js_opts)
    when "tinymce"
      html_editor_tinymce(elem, editor_opts, js_opts)
    when "markdown"
      html_editor_markdown(elem, editor_opts, js_opts)
    end
  end

  def html_editor_js(elem, editor_opts = {}, js_opts = {})
    case SS.config.cms.html_editor
    when "ckeditor"
      html_editor_ckeditor_js(elem, editor_opts, js_opts)
    when "tinymce"
      html_editor_tinymce_js(elem, editor_opts, js_opts)
    when "markdown"
      html_editor_markdown_js(elem, editor_opts, js_opts)
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
    if public_side = opts.delete(:public_side)
      public_side_options = SS.config.cms.ckeditor['public_side_options'].presence
      public_side_options ||= {}
      base_opts.merge!(public_side_options.symbolize_keys)
    end
    if opts.delete(:advanced)
      advanced_options = SS.config.cms.ckeditor['advanced_options'].presence
      advanced_options ||= {}
      base_opts.merge!(advanced_options.symbolize_keys)
    end

    base_opts = site_ckeditor_editor_options(base_opts, public_side: public_side)

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

  def html_editor_ckeditor(elem, editor_opts = {}, js_opts = {})
    jquery do
      html_editor_ckeditor_js(elem, editor_opts, js_opts)
    end
  end

  def html_editor_ckeditor_js(elem, editor_opts = {}, js_opts = {})
    SS.config.cms.ckeditor.fetch('stylesheets', []).each do |ss|
      controller.stylesheet ss
    end
    SS.config.cms.ckeditor.fetch('javascripts', []).each do |js|
      controller.javascript js
    end
    editor_opts = ckeditor_editor_options(editor_opts)

    "Cms_Editor_CKEditor.render('#{elem}', #{editor_opts.to_json}, #{js_opts.to_json});".html_safe
  end

  def tinymce_editor_options(opts = {})
    opts = opts.symbolize_keys

    base_opts = SS.config.cms.tinymce['options'].symbolize_keys
    if opts[:readonly]
      readonly_options = SS.config.cms.tinymce['readonly_options'].presence
      readonly_options ||= {}
      base_opts.merge!(readonly_options.symbolize_keys)
    elsif public_side = opts[:public_side]
      public_side_options = SS.config.cms.tinymce['public_side_options'].presence
      public_side_options ||= {}
      base_opts.merge!(public_side_options.symbolize_keys)
    else
      base_opts[:templates] = "#{template_cms_editor_templates_path}.json?_=#{Time.zone.now.to_i}"
    end

    base_opts = site_tinymce_editor_options(base_opts, public_side: public_side)
    base_opts[:plugins] ||= []

    opts.reverse_merge!(base_opts)
    opts
  end

  def html_editor_tinymce(elem, editor_opts = {}, js_opts = {})
    jquery do
      html_editor_tinymce_js(elem, editor_opts, js_opts)
    end
  end

  def html_editor_tinymce_js(elem, editor_opts = {}, js_opts = {})
    controller.javascript "/assets/js/tinymce/tinymce.min.js"
    editor_opts = tinymce_editor_options(editor_opts)

    "Cms_Editor_TinyMCE.render('#{elem}', #{editor_opts.to_json}, #{js_opts.to_json});".html_safe
  end

  def html_editor_markdown(elem, editor_opts = {}, js_opts = {})
  end
  alias html_editor_markdown_js html_editor_markdown

  def site_ckeditor_editor_options(editor_options = {}, opts = {})
    return editor_options if @cur_site.nil?
    if @cur_node
      color_button = @cur_node.try(:color_button) || @cur_site.color_button
      editor_css_path = @cur_node.try(:editor_css_path) || @cur_site.editor_css_path
    else
      color_button = @cur_site.color_button
      editor_css_path = @cur_site.editor_css_path
    end

    if color_button == 'enabled'
      editor_options[:extraPlugins] ||= %w(colorbutton)
      editor_options[:removePlugins] ||= []
      editor_options[:removePlugins] -= %w(colorbutton)
    end
    editor_options[:removePlugins] ||= %w(colorbutton) if color_button == 'disabled'

    editor_options[:contentsCss] ||= []
    if editor_css_path.present?
      if @cur_site && !opts[:public_side]
        editor_options[:contentsCss] << cms_preview_path(path: editor_css_path.sub(/^\//, ""))
      else
        editor_options[:contentsCss] << editor_css_path
      end
    end

    editor_options
  end

  def site_tinymce_editor_options(editor_options = {}, opts = {})
    return editor_options if @cur_site.nil?
    if @cur_node
      color_button = @cur_node.try(:color_button) || @cur_site.color_button
      editor_css_path = @cur_node.try(:editor_css_path) || @cur_site.editor_css_path
    else
      color_button = @cur_site.color_button
      editor_css_path = @cur_site.editor_css_path
    end

    if color_button == 'enabled'
      editor_options[:plugins] ||= []
      editor_options[:plugins].push('textcolor')
      editor_options[:plugins].uniq!
      if editor_options[:toolbar]
        editor_options[:toolbar] += ' | forecolor backcolor' unless editor_options[:toolbar].include?('forecolor backcolor')
      end
    end
    if color_button == 'disabled'
      editor_options[:plugins] ||= []
      editor_options[:plugins].delete('textcolor')
      if editor_options[:toolbar]
        editor_options[:toolbar].gsub!(' | forecolor backcolor', '')
      end
    end

    editor_options[:content_css] ||= []
    if editor_css_path.present?
      if @cur_site && !opts[:public_side]
        editor_options[:contentsCss] << cms_preview_path(path: editor_css_path.sub(/^\//, ""))
      else
        editor_options[:contentsCss] << editor_css_path
      end
    end

    editor_options
  end
end
