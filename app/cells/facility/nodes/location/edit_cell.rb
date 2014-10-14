# coding: utf-8
module Facility::Nodes::Location
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facility::Node::Location
  end
end
