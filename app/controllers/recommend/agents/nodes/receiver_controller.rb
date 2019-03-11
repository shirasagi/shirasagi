class Recommend::Agents::Nodes::ReceiverController < ApplicationController
  include Cms::NodeFilter::View
  include Recommend::ReceiverFilter
end
