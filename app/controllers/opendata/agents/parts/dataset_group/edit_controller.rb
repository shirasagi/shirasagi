module Opendata::Agents::Parts::DatasetGroup
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Opendata::Part::DatasetGroup
  end
end
