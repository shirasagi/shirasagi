module  Urgency::Agents::Nodes::Layout
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Urgency::Node::Layout
  end
end
