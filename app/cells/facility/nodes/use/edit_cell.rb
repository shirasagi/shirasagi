# coding: utf-8
module Facility::Nodes::Use
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facility::Node::Use
  end
end
