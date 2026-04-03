class Inquiry::FormsController < ApplicationController
  include Cms::BaseFilter

  def index
    menu = Inquiry.enum_menu_items(@cur_site, @cur_node, @cur_user).first
    raise "404" if menu.blank?

    redirect_to menu.path
  end
end
