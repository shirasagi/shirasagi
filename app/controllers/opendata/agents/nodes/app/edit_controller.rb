module Opendata::Agents::Nodes::App
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::App
  end
end
