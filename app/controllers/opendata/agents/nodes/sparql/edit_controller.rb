module Opendata::Agents::Nodes::Sparql
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::Sparql
  end
end
