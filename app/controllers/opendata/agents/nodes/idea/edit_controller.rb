module Opendata::Agents::Nodes::Idea
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::Idea
  end
end
