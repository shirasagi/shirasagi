# coding: utf-8
module Facility::Nodes::Category
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facility::Node::Category
  end
end
