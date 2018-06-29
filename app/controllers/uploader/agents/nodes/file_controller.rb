class Uploader::Agents::Nodes::FileController < ApplicationController
  include Cms::NodeFilter::View

  def index
    head :ok
  end
end
