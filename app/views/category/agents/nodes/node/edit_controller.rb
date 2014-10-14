module Category::Nodes::Node
  class EditController < ApplicationController
    include Cms::NodeFilter::EditCell
    model Category::Node::Node
  end
end
