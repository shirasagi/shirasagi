class Cms::Frames::TempFilesController < ApplicationController
  include Cms::BaseFilter

  model SS::File

  layout 'ss/item_frame'

  def index
    render
  end
end
