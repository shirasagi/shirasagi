module  Urgency::Nodes::Layout
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Urgency::Node::Layout
  end
end
