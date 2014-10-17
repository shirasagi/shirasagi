module Opendata::Agents::Nodes::MyProfile
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::MyProfile
  end
end
