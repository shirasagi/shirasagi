# coding: utf-8
module Map::Nodes::Page
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Faq::Node::Page
  end
end
