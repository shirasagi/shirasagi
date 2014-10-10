module Cms::Nodes::Node
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Cms::Node::Node
  end
end
