module Facility::Agents::Nodes::Feature
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Feature
  end
end
