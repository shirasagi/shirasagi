class KeyVisual::Agents::Nodes::ImageController < ApplicationController
  include Cms::NodeFilter::View

  def index
    render nothing: true
  end
end
