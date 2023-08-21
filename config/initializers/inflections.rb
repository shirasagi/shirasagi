# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end

# register acronym "SS" for loading classes under module "SS" with Zeitwerk class loader.
#
# see:
# - https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#customizing-inflections
# - https://qiita.com/alfa/items/3a432c31346a705d0690
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'SS'
  inflect.acronym 'OAuth'
  inflect.acronym 'OAuth2'
  inflect.acronym 'JWT'
end
