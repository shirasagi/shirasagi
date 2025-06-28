class Inquiry2::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::ColumnFilter2

  model Cms::Column::Base
  self.form_model = Inquiry2::Node::Form

  navi_view "inquiry2/main/navi"
  append_view_path 'app/views/cms/columns2'

  before_action :check_permission

  private

  def column_route_options
    Inquiry2::Column.route_options
  end

  def check_permission
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
  end

  def cur_form
    @cur_form ||= @cur_node
  end
end
