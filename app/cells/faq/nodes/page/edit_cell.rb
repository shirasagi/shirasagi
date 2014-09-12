# coding: utf-8
module Faq::Nodes::Page
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Faq::Node::Page
  end
end
