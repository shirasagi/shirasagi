# coding: utf-8
module Category::Nodes::Page
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Category::Node::Page
  end
end
