module Opendata::Nodes::Area
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Area
  end
end
