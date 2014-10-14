# coding: utf-8
module Facility::Nodes::Search
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facility::Node::Search
  end
end
