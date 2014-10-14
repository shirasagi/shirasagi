module Cms::Agents::Nodes::Node
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Cms::Node::Node
  end
end
