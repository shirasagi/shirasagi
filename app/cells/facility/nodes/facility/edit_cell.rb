# coding: utf-8
module Facility::Nodes::Facility
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facility::Node::Facility
  end
end
