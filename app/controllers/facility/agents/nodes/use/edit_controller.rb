module Facility::Agents::Nodes::Use
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Use
  end
end
