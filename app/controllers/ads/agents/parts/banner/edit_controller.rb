module Ads::Agents::Parts::Banner
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Ads::Part::Banner
  end
end
