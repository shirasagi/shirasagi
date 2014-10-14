module Category::Agents::Nodes::Node
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Category::Node::Node
  end
end
