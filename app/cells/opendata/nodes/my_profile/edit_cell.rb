# coding: utf-8
module Opendata::Nodes::MyProfile
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::MyProfile
  end
end
