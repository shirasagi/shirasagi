module  Inquiry::Agents::Nodes::Form
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Inquiry::Agents::Node::Form
  end
end
