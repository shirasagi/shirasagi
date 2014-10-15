module Facility::Agents::Nodes::Node
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Node
  end
end
