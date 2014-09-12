# coding: utf-8
module Category::Nodes::Node
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Category::Node::Node
  end
end
