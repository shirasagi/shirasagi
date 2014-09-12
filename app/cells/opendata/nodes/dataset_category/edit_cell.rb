# coding: utf-8
module Opendata::Nodes::DatasetCategory
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::DatasetCategory
  end
end
