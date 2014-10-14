module Category::Agents::Nodes::Page
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Category::Node::Page
  end
end
