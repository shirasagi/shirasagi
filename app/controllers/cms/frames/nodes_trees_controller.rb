class Cms::Frames::NodesTreesController < ApplicationController
  include Cms::BaseFilter

  model Cms::Node

  def index
    render :index, layout: false
  end
end
