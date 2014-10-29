module Facility::Agents::Nodes::Attribute
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Attribute
  end
end
