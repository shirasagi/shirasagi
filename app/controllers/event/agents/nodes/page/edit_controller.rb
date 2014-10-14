module  Event::Agents::Nodes::Page
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Event::Node::Page
  end
end
