module Opendata
  class Initializer
    Cms::Node.plugin "opendata/category"
    Cms::Node.plugin "opendata/area"
    Cms::Node.plugin "opendata/dataset"
    Cms::Node.plugin "opendata/dataset_category"
    Cms::Node.plugin "opendata/search_dataset"
    Cms::Node.plugin "opendata/search_dataset_group"
    Cms::Node.plugin "opendata/sparql"
    Cms::Node.plugin "opendata/api"
    Cms::Node.plugin "opendata/mypage"
    Cms::Node.plugin "opendata/my_dataset"
    Cms::Node.plugin "opendata/app"
    Cms::Node.plugin "opendata/idea"

    Cms::Role.permission :read_other_opendata_datasets
    Cms::Role.permission :read_private_opendata_datasets
    Cms::Role.permission :edit_other_opendata_datasets
    Cms::Role.permission :edit_private_opendata_datasets
    Cms::Role.permission :delete_other_opendata_datasets
    Cms::Role.permission :delete_private_opendata_datasets
    Cms::Role.permission :read_other_opendata_apps
    Cms::Role.permission :read_private_opendata_apps
    Cms::Role.permission :edit_other_opendata_apps
    Cms::Role.permission :edit_private_opendata_apps
    Cms::Role.permission :delete_other_opendata_apps
    Cms::Role.permission :delete_private_opendata_apps
    Cms::Role.permission :read_other_opendata_ideas
    Cms::Role.permission :read_private_opendata_ideas
    Cms::Role.permission :edit_other_opendata_ideas
    Cms::Role.permission :edit_private_opendata_ideas
    Cms::Role.permission :delete_other_opendata_ideas
    Cms::Role.permission :delete_private_opendata_ideas
  end
end
