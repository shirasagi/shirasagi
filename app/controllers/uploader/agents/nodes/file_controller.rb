class Uploader::Agents::Nodes::FileController < ApplicationController
  include Cms::NodeFilter::View

  def index
    render nothing: true
  end
end
