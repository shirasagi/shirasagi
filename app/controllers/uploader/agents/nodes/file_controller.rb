class Uploader::Agents::Nodes::FileController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  public
    def index
      render nothing: true
    end
end
