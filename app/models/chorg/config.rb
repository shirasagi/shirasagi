class Chorg::Config
  cattr_reader(:default_values) do
    {
      models: [ "Cms::Part", "Cms::Layout", "Cms::Node", "Cms::Page" ],
      exclude_fields: [ "filename", "state", "/_state$/", "md5", "route", "/_route$/",
                        "workflow_state", "workflow_comment", "url", "/_url$/" ],
      ids_fields: [ "_id", "id" ],
      max_division: 3
    }
  end
end
