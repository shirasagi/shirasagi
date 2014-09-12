# coding: utf-8
module Opendata::Nodes::Mypage
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Mypage
  end
end
