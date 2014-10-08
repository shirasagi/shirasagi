# coding: utf-8
module Opendata::Nodes::SearchDataset
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::SearchDataset
  end
end
