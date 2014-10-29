module Facility::Agents::Nodes::Search
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Search
  end
end
