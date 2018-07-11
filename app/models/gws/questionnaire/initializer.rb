class Gws::Questionnaire::Initializer
  Gws::Role.permission :read_other_gws_questionnaire_forms, module_name: 'gws/questionnaire'
  Gws::Role.permission :read_private_gws_questionnaire_forms, module_name: 'gws/questionnaire'
  Gws::Role.permission :edit_other_gws_questionnaire_forms, module_name: 'gws/questionnaire'
  Gws::Role.permission :edit_private_gws_questionnaire_forms, module_name: 'gws/questionnaire'
  Gws::Role.permission :delete_other_gws_questionnaire_forms, module_name: 'gws/questionnaire'
  Gws::Role.permission :delete_private_gws_questionnaire_forms, module_name: 'gws/questionnaire'
  Gws::Role.permission :trash_other_gws_questionnaire_forms, module_name: 'gws/questionnaire'
  Gws::Role.permission :trash_private_gws_questionnaire_forms, module_name: 'gws/questionnaire'

  Gws::Role.permission :read_other_gws_questionnaire_categories, module_name: 'gws/questionnaire'
  Gws::Role.permission :read_private_gws_questionnaire_categories, module_name: 'gws/questionnaire'
  Gws::Role.permission :edit_other_gws_questionnaire_categories, module_name: 'gws/questionnaire'
  Gws::Role.permission :edit_private_gws_questionnaire_categories, module_name: 'gws/questionnaire'
  Gws::Role.permission :delete_other_gws_questionnaire_categories, module_name: 'gws/questionnaire'
  Gws::Role.permission :delete_private_gws_questionnaire_categories, module_name: 'gws/questionnaire'
end
