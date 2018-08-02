class Gws::Survey::Initializer
  Gws::Role.permission :read_other_gws_survey_forms, module_name: 'gws/survey'
  Gws::Role.permission :read_private_gws_survey_forms, module_name: 'gws/survey'
  Gws::Role.permission :edit_other_gws_survey_forms, module_name: 'gws/survey'
  Gws::Role.permission :edit_private_gws_survey_forms, module_name: 'gws/survey'
  Gws::Role.permission :delete_other_gws_survey_forms, module_name: 'gws/survey'
  Gws::Role.permission :delete_private_gws_survey_forms, module_name: 'gws/survey'
  Gws::Role.permission :trash_other_gws_survey_forms, module_name: 'gws/survey'
  Gws::Role.permission :trash_private_gws_survey_forms, module_name: 'gws/survey'

  Gws::Role.permission :read_other_gws_survey_categories, module_name: 'gws/survey'
  Gws::Role.permission :read_private_gws_survey_categories, module_name: 'gws/survey'
  Gws::Role.permission :edit_other_gws_survey_categories, module_name: 'gws/survey'
  Gws::Role.permission :edit_private_gws_survey_categories, module_name: 'gws/survey'
  Gws::Role.permission :delete_other_gws_survey_categories, module_name: 'gws/survey'
  Gws::Role.permission :delete_private_gws_survey_categories, module_name: 'gws/survey'
end
