# coding: utf-8
module Facilitiy::Nodes::Category
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Facilitiy::Node::Category
  end
end
