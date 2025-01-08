class Cms::Frames::NodesTreesController < ApplicationController
  include Cms::BaseFilter

  model Cms::Node

  def index
    render Cms::NodesTreeComponent.new(site: @cur_site, user: @cur_user), layout: false
  end

  def super_reload
    render Cms::NodesTreeComponent.new(site: @cur_site, user: @cur_user, cache_mode: "refresh"), layout: false
  end
end
