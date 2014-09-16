# coding: utf-8
module  Inquiry::Nodes::Form
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Inquiry::Node::Form
  end
end
