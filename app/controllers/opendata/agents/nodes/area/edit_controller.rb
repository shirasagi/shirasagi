module Opendata::Agents::Nodes::Area
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::Area
  end
end
