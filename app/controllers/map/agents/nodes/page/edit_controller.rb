module Map::Agents::Nodes::Page
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Map::Node::Page
  end
end
