module Cms::Agents::Parts::Page
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Cms::Part::Page
  end
end
