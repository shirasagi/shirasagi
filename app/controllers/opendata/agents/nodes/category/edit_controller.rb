module Opendata::Agents::Nodes::Category
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::Category
  end
end
