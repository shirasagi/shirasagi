class Gws::File
  class Initializer
    Gws::GroupSetting.plugin Gws::File::GroupSetting, ->{ gws_file_setting_path }

    Gws::Role.permission :read_other_gws_file_settings, module_name: 'gws/file'
    Gws::Role.permission :read_private_gws_file_settings, module_name: 'gws/file'
    Gws::Role.permission :edit_other_gws_file_settings, module_name: 'gws/file'
    Gws::Role.permission :edit_private_gws_file_settings, module_name: 'gws/file'
    Gws::Role.permission :delete_other_gws_file_settings, module_name: 'gws/file'
    Gws::Role.permission :delete_private_gws_file_settings, module_name: 'gws/file'
  end
end
