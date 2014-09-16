# coding: utf-8
module Article::Nodes::Page
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Article::Node::Page
  end
end
