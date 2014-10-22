module Cms::Agents::Parts::SnsShare
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Cms::Part::SnsShare
  end
end
