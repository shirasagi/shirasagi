module Uploader::Agents::Nodes::File
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model ::Cms::Node
  end
end
