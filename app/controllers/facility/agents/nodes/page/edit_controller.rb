module Facility::Agents::Nodes::Page
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Page
  end
end
