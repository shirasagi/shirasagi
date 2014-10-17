module Opendata::Agents::Nodes::DatasetCategory
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::DatasetCategory
  end
end
