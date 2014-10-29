module Facility::Agents::Nodes::Service
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Service
  end
end
