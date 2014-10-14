module Cms::Agents::Parts::Crumb
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Cms::Part::Crumb
  end
end
