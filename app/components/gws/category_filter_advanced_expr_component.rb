class Gws::CategoryFilterAdvancedExprComponent < ApplicationComponent
  include ActiveModel::Model
  include Gws::LayoutHelper

  attr_accessor :cur_site, :cur_user, :category_model, :category_filter
  attr_writer :categories

  def categories
    @categories ||= category_model.all.site(cur_site).readable(@cur_user, site: @cur_site).reorder(order: 1, name: 1).to_a
  end
end
