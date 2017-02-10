class KeyVisual::Agents::Nodes::ImageController < ApplicationController
  include Cms::NodeFilter::View

  def index
    head :ok
  end
end
