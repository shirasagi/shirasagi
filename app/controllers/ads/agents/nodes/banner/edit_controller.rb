module Ads::Agents::Nodes::Banner
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Ads::Node::Banner
  end
end
