module Opendata::Nodes::SearchGroup
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::SearchGroup
  end
end
