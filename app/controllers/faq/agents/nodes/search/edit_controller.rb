module Faq::Agents::Nodes::Search
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Faq::Node::Search
  end
end
