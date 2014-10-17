module Opendata::Agents::Parts::Dataset
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Opendata::Part::Dataset
  end
end
