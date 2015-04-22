class Cms::Config
  cattr_reader(:default_values) do
    {
      serve_static_pages: true,
      html_editor: "ckeditor",
      map_center: [36.204824, 138.252924],
    }
  end
end
