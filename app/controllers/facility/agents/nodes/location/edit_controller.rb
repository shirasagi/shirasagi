module Facility::Agents::Nodes::Location
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Location
  end
end
