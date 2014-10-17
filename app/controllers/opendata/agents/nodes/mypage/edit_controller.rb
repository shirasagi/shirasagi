module Opendata::Agents::Nodes::Mypage
  class EditController < ApplicationController
    include Cms::NodeFilter::Edit
    model Opendata::Node::Mypage
  end
end
