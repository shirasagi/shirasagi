class Gws::Form::Initializer
  Gws::Role.permission :read_other_gws_form_forms, module_name: 'gws/form'
  Gws::Role.permission :read_private_gws_form_forms, module_name: 'gws/form'
  Gws::Role.permission :edit_other_gws_form_forms, module_name: 'gws/form'
  Gws::Role.permission :edit_private_gws_form_forms, module_name: 'gws/form'
  Gws::Role.permission :delete_other_gws_form_forms, module_name: 'gws/form'
  Gws::Role.permission :delete_private_gws_form_forms, module_name: 'gws/form'
  Gws::Role.permission :trash_other_gws_form_forms, module_name: 'gws/form'
  Gws::Role.permission :trash_private_gws_form_forms, module_name: 'gws/form'

  Gws::Role.permission :read_other_gws_form_categories, module_name: 'gws/form'
  Gws::Role.permission :read_private_gws_form_categories, module_name: 'gws/form'
  Gws::Role.permission :edit_other_gws_form_categories, module_name: 'gws/form'
  Gws::Role.permission :edit_private_gws_form_categories, module_name: 'gws/form'
  Gws::Role.permission :delete_other_gws_form_categories, module_name: 'gws/form'
  Gws::Role.permission :delete_private_gws_form_categories, module_name: 'gws/form'
end
