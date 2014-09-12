# coding: utf-8
module Opendata::Nodes::App
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::App
  end
end
