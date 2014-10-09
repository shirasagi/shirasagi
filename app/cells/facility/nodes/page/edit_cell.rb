# coding: utf-8
module Facility::Nodes::Page
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facility::Node::Page
  end
end
