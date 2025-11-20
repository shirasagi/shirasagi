class Inquiry::FormsController < ApplicationController
  include Cms::BaseFilter

  def index
    if @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      redirect_to inquiry_columns_path
    elsif @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      redirect_to inquiry_answers_path
    else
      raise '403'
    end
  end
end
