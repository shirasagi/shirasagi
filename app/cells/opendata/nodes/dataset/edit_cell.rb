module Opendata::Nodes::Dataset
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Dataset
  end
end
