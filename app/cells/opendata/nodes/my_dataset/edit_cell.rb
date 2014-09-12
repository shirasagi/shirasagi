# coding: utf-8
module Opendata::Nodes::MyDataset
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::MyDataset
  end
end
