module Faq::Agents::Parts::Search
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Faq::Part::Search
  end
end
