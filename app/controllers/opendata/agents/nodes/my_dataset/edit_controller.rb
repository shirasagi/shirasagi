module Opendata::Agents::Nodes::MyDataset
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::MyDataset
  end
end
