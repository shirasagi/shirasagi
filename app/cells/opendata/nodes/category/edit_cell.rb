module Opendata::Nodes::Category
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Category
  end
end
