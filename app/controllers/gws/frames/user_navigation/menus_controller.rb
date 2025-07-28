class Gws::Frames::UserNavigation::MenusController < ApplicationController
  include Gws::BaseFilter

  layout "ss/item_frame"

  before_action :set_frame_id

  private

  def set_item
  end

  def set_frame_id
    @frame_id = "user-navigation-frame"
  end

  public

  def show
    render
  end
end
