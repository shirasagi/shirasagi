module Opendata::Agents::Nodes::SearchGroup
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::SearchGroup
  end
end
