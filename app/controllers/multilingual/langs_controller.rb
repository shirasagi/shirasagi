class Multilingual::LangsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Multilingual::Node::Lang

  menu_view nil
  navi_view "cms/main/navi"

  def index
    @items = []
  end
end
