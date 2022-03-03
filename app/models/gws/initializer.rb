module Gws
  class Initializer
    Gws::Column.plugin 'gws/text_field'
    Gws::Column.plugin 'gws/date_field'
    Gws::Column.plugin 'gws/number_field'
    Gws::Column.plugin 'gws/url_field'
    Gws::Column.plugin 'gws/text_area'
    Gws::Column.plugin 'gws/select'
    Gws::Column.plugin 'gws/radio_button'
    Gws::Column.plugin 'gws/check_box'
    Gws::Column.plugin 'gws/file_upload'

    Gws::Role.permission :edit_gws_groups
    Gws::Role.permission :edit_gws_users
    Gws::Role.permission :edit_gws_user_titles
    Gws::Role.permission :edit_gws_user_occupations
    Gws::Role.permission :edit_gws_roles
    Gws::Role.permission :edit_gws_user_forms
    Gws::Role.permission :read_gws_histories
    Gws::Role.permission :read_gws_job_logs

    Gws::Role.permission :read_other_gws_custom_groups
    Gws::Role.permission :read_private_gws_custom_groups
    Gws::Role.permission :edit_other_gws_custom_groups
    Gws::Role.permission :edit_private_gws_custom_groups
    Gws::Role.permission :delete_other_gws_custom_groups
    Gws::Role.permission :delete_private_gws_custom_groups
    Gws::Role.permission :delete_gws_histories

    Gws::Role.permission :read_other_gws_links
    Gws::Role.permission :read_private_gws_links
    Gws::Role.permission :edit_other_gws_links
    Gws::Role.permission :edit_private_gws_links
    Gws::Role.permission :delete_other_gws_links
    Gws::Role.permission :delete_private_gws_links

    Gws::Role.permission :read_gws_organization
    Gws::Role.permission :edit_gws_contrasts
    Gws::Role.permission :edit_gws_bookmarks
    Gws::Role.permission :edit_gws_personal_addresses

    SS::File.model "gws/file", Gws::File
    SS::File.model "share/file", Gws::Share::File
    SS::File.model "gws/history_archive_file", Gws::HistoryArchiveFile

    Gws.module_usable :bookmark do |site, user|
      Gws::Bookmark.allowed?(:read, user, site: site)
    end

    Gws.module_usable :personal_address do |site, user|
      user.gws_role_permit_any?(site, :edit_gws_personal_addresses)
    end
  end
end
