module Cms::Agents::Parts::Node
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Cms::Part::Node
  end
end
