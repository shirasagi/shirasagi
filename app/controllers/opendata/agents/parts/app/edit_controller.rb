module Opendata::Agents::Parts::App
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Opendata::Part::App
  end
end
