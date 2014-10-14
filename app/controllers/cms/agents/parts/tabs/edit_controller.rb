module Cms::Agents::Parts::Tabs
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Cms::Part::Tabs
  end
end
