class Gws::Tabular::Column::FileUploadFieldComponent < ApplicationComponent
  include ActiveModel::Model
  include ApplicationHelper

  strip_trailing_whitespace

  attr_accessor :cur_site, :cur_user, :value, :type, :column, :form, :item, :locale
end
