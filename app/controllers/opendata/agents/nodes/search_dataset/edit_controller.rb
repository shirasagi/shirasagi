module Opendata::Agents::Nodes::SearchDataset
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::SearchDataset
  end
end
