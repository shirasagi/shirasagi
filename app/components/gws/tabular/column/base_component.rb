class Gws::Tabular::Column::BaseComponent < ApplicationComponent
  include ActiveModel::Model
  include ApplicationHelper

  strip_trailing_whitespace

  attr_accessor :cur_site, :cur_user, :type, :column
end
