module Opendata
  class Initializer
    Cms::Node.plugin "opendata/category"
    Cms::Node.plugin "opendata/estat_category"
    Cms::Node.plugin "opendata/area"
    Cms::Node.plugin "opendata/dataset"
    Cms::Node.plugin "opendata/dataset_category"
    Cms::Node.plugin "opendata/dataset_estat_category"
    Cms::Node.plugin "opendata/dataset_area"
    Cms::Node.plugin "opendata/search_dataset_group"
    Cms::Node.plugin "opendata/search_dataset"
    Cms::Node.plugin "opendata/dataset_map"
    Cms::Node.plugin "opendata/sparql"
    Cms::Node.plugin "opendata/api"
    Cms::Node.plugin "opendata/app"
    Cms::Node.plugin "opendata/app_category"
    Cms::Node.plugin "opendata/search_app"
    Cms::Node.plugin "opendata/idea"
    Cms::Node.plugin "opendata/idea_category"
    Cms::Node.plugin "opendata/search_idea"
    Cms::Node.plugin "opendata/mypage"
    Cms::Node.plugin "opendata/member"
    Cms::Node.plugin "opendata/my_profile"
    Cms::Node.plugin "opendata/my_dataset"
    Cms::Node.plugin "opendata/my_app"
    Cms::Node.plugin "opendata/my_idea"

    Cms::Part.plugin "opendata/app"
    Cms::Part.plugin "opendata/idea"
    Cms::Part.plugin "opendata/dataset"
    Cms::Part.plugin "opendata/dataset_group"
    Cms::Part.plugin "opendata/dataset_counter"
    Cms::Part.plugin "opendata/mypage_login"

    Cms::Role.permission :read_other_opendata_datasets
    Cms::Role.permission :read_private_opendata_datasets
    Cms::Role.permission :read_member_opendata_datasets
    Cms::Role.permission :edit_other_opendata_datasets
    Cms::Role.permission :edit_private_opendata_datasets
    Cms::Role.permission :edit_member_opendata_datasets
    Cms::Role.permission :delete_other_opendata_datasets
    Cms::Role.permission :delete_private_opendata_datasets
    Cms::Role.permission :delete_member_opendata_datasets
    Cms::Role.permission :release_other_opendata_datasets
    Cms::Role.permission :release_private_opendata_datasets
    Cms::Role.permission :release_member_opendata_datasets
    Cms::Role.permission :approve_other_opendata_datasets
    Cms::Role.permission :approve_private_opendata_datasets
    Cms::Role.permission :approve_member_opendata_datasets
    Cms::Role.permission :reroute_other_opendata_datasets
    Cms::Role.permission :reroute_private_opendata_datasets
    Cms::Role.permission :revoke_other_opendata_datasets
    Cms::Role.permission :revoke_private_opendata_datasets
    Cms::Role.permission :import_other_opendata_datasets

    Cms::Role.permission :read_other_opendata_apps
    Cms::Role.permission :read_private_opendata_apps
    Cms::Role.permission :read_member_opendata_apps
    Cms::Role.permission :edit_other_opendata_apps
    Cms::Role.permission :edit_private_opendata_apps
    Cms::Role.permission :edit_member_opendata_apps
    Cms::Role.permission :delete_other_opendata_apps
    Cms::Role.permission :delete_private_opendata_apps
    Cms::Role.permission :delete_member_opendata_apps
    Cms::Role.permission :release_other_opendata_apps
    Cms::Role.permission :release_private_opendata_apps
    Cms::Role.permission :release_member_opendata_apps
    Cms::Role.permission :approve_other_opendata_apps
    Cms::Role.permission :approve_private_opendata_apps
    Cms::Role.permission :approve_member_opendata_apps
    Cms::Role.permission :reroute_other_opendata_apps
    Cms::Role.permission :reroute_private_opendata_apps
    Cms::Role.permission :revoke_other_opendata_apps
    Cms::Role.permission :revoke_private_opendata_apps

    Cms::Role.permission :read_other_opendata_ideas
    Cms::Role.permission :read_private_opendata_ideas
    Cms::Role.permission :read_member_opendata_ideas
    Cms::Role.permission :edit_other_opendata_ideas
    Cms::Role.permission :edit_private_opendata_ideas
    Cms::Role.permission :edit_member_opendata_ideas
    Cms::Role.permission :delete_other_opendata_ideas
    Cms::Role.permission :delete_private_opendata_ideas
    Cms::Role.permission :delete_member_opendata_ideas
    Cms::Role.permission :release_other_opendata_ideas
    Cms::Role.permission :release_private_opendata_ideas
    Cms::Role.permission :release_member_opendata_ideas
    Cms::Role.permission :approve_other_opendata_ideas
    Cms::Role.permission :approve_private_opendata_ideas
    Cms::Role.permission :approve_member_opendata_ideas
    Cms::Role.permission :reroute_other_opendata_ideas
    Cms::Role.permission :reroute_private_opendata_ideas
    Cms::Role.permission :revoke_other_opendata_ideas
    Cms::Role.permission :revoke_private_opendata_ideas

    Cms::Role.permission :edit_other_opendata_harvests
    Cms::Role.permission :edit_other_opendata_harvested

    Cms::Role.permission :edit_other_opendata_public_entity_datasets

    Cms::Role.permission :read_opendata_reports
    Cms::Role.permission :read_opendata_histories

    SS::File.model "opendata/dataset", SS::File, permit: %i(role)
    SS::File.model "opendata/resource", SS::File, permit: %i(role)
    SS::File.model "opendata/url_resource", SS::File, permit: %i(role)
    SS::File.model "opendata/app", SS::File, permit: %i(role)
    SS::File.model "opendata/appfile", SS::File, permit: %i(role)
    SS::File.model "opendata/idea", SS::File, permit: %i(role)
    Opendata::ResourceDownloadHistory::ArchiveFile.tap do |model|
      SS::File.model model.model_name.i18n_key.to_s, model
    end
    Opendata::ResourcePreviewHistory::ArchiveFile.tap do |model|
      SS::File.model model.model_name.i18n_key.to_s, model
    end
  end
end
