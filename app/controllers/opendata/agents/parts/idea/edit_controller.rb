module Opendata::Agents::Parts::Idea
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Opendata::Part::Idea
  end
end
