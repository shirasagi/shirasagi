module Cms::Agents::Parts::Free
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Cms::Part::Free
  end
end
