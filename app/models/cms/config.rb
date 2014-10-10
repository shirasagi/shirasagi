class Cms::Config
  cattr_reader(:default_values) do
    {
      serve_static_pages: true,
      html_editor: "ckeditor"
    }
  end
end
