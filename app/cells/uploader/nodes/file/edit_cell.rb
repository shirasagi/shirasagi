# coding: utf-8
module Uploader::Nodes::File
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model ::Cms::Node
  end
end
