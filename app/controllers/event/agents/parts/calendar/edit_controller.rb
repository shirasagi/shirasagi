module Event::Agents::Parts::Calendar
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Event::Part::Calendar
  end
end
