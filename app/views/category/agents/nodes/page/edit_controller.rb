module Category::Nodes::Page
  class EditController < ApplicationController
    include Cms::NodeFilter::EditCell
    model Category::Node::Page
  end
end
