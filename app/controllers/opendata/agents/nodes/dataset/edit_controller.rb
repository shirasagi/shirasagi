module Opendata::Agents::Nodes::Dataset
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::Dataset
  end
end
