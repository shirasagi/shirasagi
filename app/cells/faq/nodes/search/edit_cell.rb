# coding: utf-8
module Faq::Nodes::Search
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Faq::Node::Search
  end
end
