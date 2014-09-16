# coding: utf-8
module Facilitiy::Nodes::Page
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facilitiy::Node::Page
  end
end
