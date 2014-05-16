# encoding: utf-8
class Cms::Config
  cattr_reader(:default_values) do
    {
      ajax_layout: true,
      ajax_free_part: false,
      serve_static_pages: true,
      serve_static_layouts: false,
      html_editor: "ckeditor"
    }
  end
end
