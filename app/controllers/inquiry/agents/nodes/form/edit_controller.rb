module  Inquiry::Agents::Nodes::Form
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Inquiry::Node::Form
  end
end
