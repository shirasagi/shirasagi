class Gws::Tabular::Column::TextFieldComponent::ShowColor < ApplicationComponent
  include ActiveModel::Model
  include Gws::Tabular::Column::TextFieldComponent::Base
  include SS::ColorPickerHelper
end
