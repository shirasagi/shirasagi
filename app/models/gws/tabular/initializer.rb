class Gws::Tabular::Initializer
  Gws::Role.permission :use_gws_tabular, module_name: 'gws/tabular'

  Gws::Role.permission :read_other_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :read_private_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :edit_other_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :edit_private_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :delete_other_gws_tabular_spaces, module_name: 'gws/tabular'
  Gws::Role.permission :delete_private_gws_tabular_spaces, module_name: 'gws/tabular'

  Gws::Role.permission :read_other_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :read_private_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :edit_other_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :edit_private_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :delete_other_gws_tabular_forms, module_name: 'gws/tabular'
  Gws::Role.permission :delete_private_gws_tabular_forms, module_name: 'gws/tabular'

  Gws::Role.permission :read_other_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :read_private_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :edit_other_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :edit_private_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :delete_other_gws_tabular_views, module_name: 'gws/tabular'
  Gws::Role.permission :delete_private_gws_tabular_views, module_name: 'gws/tabular'

  Gws::Role.permission :read_gws_tabular_files, module_name: 'gws/tabular'
  Gws::Role.permission :edit_gws_tabular_files, module_name: 'gws/tabular'
  Gws::Role.permission :delete_gws_tabular_files, module_name: 'gws/tabular'
  Gws::Role.permission :download_gws_tabular_files, module_name: 'gws/tabular'
  Gws::Role.permission :import_gws_tabular_files, module_name: 'gws/tabular'

  Gws::Tabular::View.plugin Gws::Tabular::View::List.as_plugin
  Gws::Tabular::View.plugin Gws::Tabular::View::Liquid.as_plugin

  Gws::Tabular::Column.plugin Gws::Tabular::Column::TextField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::DateTimeField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::NumberField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::FileUploadField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::EnumField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::ReferenceField.as_plugin
  Gws::Tabular::Column.plugin Gws::Tabular::Column::LookupField.as_plugin

  Gws.module_usable :tabular do |site, user|
    Gws::Tabular.allowed?(:use, user, site: site)
  end
end
