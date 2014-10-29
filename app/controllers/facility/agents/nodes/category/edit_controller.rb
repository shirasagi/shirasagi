module Facility::Agents::Nodes::Category
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Facility::Node::Category
  end
end
