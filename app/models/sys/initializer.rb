module Sys
  class Initializer
    Sys::Role.permission :edit_sys_sites
    Sys::Role.permission :edit_sys_groups
    Sys::Role.permission :edit_sys_notices
    Sys::Role.permission :edit_sys_settings
    Sys::Role.permission :edit_sys_users
    Sys::Role.permission :edit_sys_roles
    Sys::Role.permission :edit_sys_mail_logs

    Sys::Role.permission :use_cms, module_name: 'sys'
    Sys::Role.permission :use_gws, module_name: 'sys'
    Sys::Role.permission :use_webmail, module_name: 'sys'

    Sys::Role.permission :edit_sys_user_account, module_name: 'sys'
    Sys::Role.permission :edit_password_sys_user_account, module_name: 'sys'

    SS::File.model "sys/history_archive_file", Sys::HistoryArchiveFile
  end
end
