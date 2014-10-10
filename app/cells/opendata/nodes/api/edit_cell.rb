module Opendata::Nodes::Api
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Sparql
  end
end
