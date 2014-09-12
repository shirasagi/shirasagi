# coding: utf-8
module Opendata::Nodes::Idea
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Idea
  end
end
