class KeyVisual::Agents::Nodes::ImageController < ApplicationController
  include Cms::NodeFilter::View

  public
    def index
      render nothing: true
    end
end
