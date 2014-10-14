# coding: utf-8
module Facility::Nodes::Node
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facility::Node::Node
  end
end
