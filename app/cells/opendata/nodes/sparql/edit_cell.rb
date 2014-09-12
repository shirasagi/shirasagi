# coding: utf-8
module Opendata::Nodes::Sparql
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Sparql
  end
end
