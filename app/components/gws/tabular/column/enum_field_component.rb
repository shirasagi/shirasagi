class Gws::Tabular::Column::EnumFieldComponent < ApplicationComponent
  include ActiveModel::Model
  include Gws::Tabular::Column::EnumFieldComponent::Base

  def call
    if type == :form
      case input_type
      when "checkbox"
        component_class = Checkbox
      when "select"
        component_class = Select
      else # "radio"
        component_class = Radio
      end
    else
      component_class = Show
    end

    component = component_class.new(
      cur_site: cur_site, cur_user: cur_user, value: value, type: type, column: column, form: form, locale: locale)
    render component
  end
end
