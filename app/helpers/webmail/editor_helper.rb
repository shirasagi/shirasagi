module Webmail::EditorHelper
  extend ActiveSupport::Concern

  def webmail_html_editor(elem, opts = {})
    case SS.config.webmail.html_editor
    when "ckeditor"
      webmail_html_editor_ckeditor(elem, opts)
    when "tinymce"
      webmail_html_editor_tinymce(elem, opts)
    when "markdown"
      webmail_html_editor_markdown(elem, opts)
    end
  end

  def webmail_html_editor_options(opts = {})
    case SS.config.webmail.html_editor
    when "ckeditor"
      webmail_ckeditor_editor_options(opts)
    when "tinymce"
      webmail_tinymce_editor_options(opts)
    when "markdown"
      #webmail_markdown_editor_options(elem, opts)
    end
  end

  def webmail_ckeditor_editor_options(opts = {})
    opts = opts.symbolize_keys

    base_opts = SS.config.webmail.ckeditor['options'].symbolize_keys
    if opts.delete(:readonly)
      readonly_options = SS.config.webmail.ckeditor['readonly_options'].presence
      readonly_options ||= {}
      base_opts.merge!(readonly_options.symbolize_keys)
    end
    if opts.delete(:advanced)
      advanced_options = SS.config.webmail.ckeditor['advanced_options'].presence
      advanced_options ||= {}
      base_opts.merge!(advanced_options.symbolize_keys)
    end

    opts.reverse_merge!(base_opts)
    opts[:extraPlugins] = opts[:extraPlugins].join(',') if opts[:extraPlugins].is_a?(Array)
    opts[:removePlugins] = opts[:removePlugins].join(',') if opts[:removePlugins].is_a?(Array)
    opts[:extraPlugins] ||= ''
    opts[:removePlugins] ||= ''

    opts
  end

  def webmail_html_editor_ckeditor(elem, opts = {})
    SS.config.webmail.ckeditor.fetch('stylesheets', []).each do |ss|
      controller.stylesheet ss
    end
    SS.config.webmail.ckeditor.fetch('javascripts', []).each do |js|
      controller.javascript js
    end
    opts = webmail_ckeditor_editor_options(opts)
    jquery do
      "Cms_Editor_CKEditor.render('#{elem}', #{opts.to_json});".html_safe
    end
  end

  def webmail_tinymce_editor_options(opts = {})
    opts = opts.symbolize_keys

    base_opts = SS.config.cms.tinymce['options'].symbolize_keys
    if opts[:readonly]
      readonly_options = SS.config.cms.tinymce['readonly_options'].presence
      readonly_options ||= {}
      base_opts.merge!(readonly_options.symbolize_keys)
    end

    base_opts = site_tinymce_editor_options(base_opts)
    base_opts[:plugins] ||= []

    opts.reverse_merge!(base_opts)
    opts
  end

  def webmail_html_editor_tinymce(elem, opts = {})
    controller.javascript "/assets/js/tinymce/tinymce.min.js"
    editor_opts = tinymce_editor_options(opts)
    jquery do
      "Cms_Editor_TinyMCE.render('#{elem}', #{editor_opts.to_json});".html_safe
    end
  end

  def webmail_html_editor_markdown(elem, opts = {})
  end
end
