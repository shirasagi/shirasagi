module Opendata::Agents::Parts::MypageLogin
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Opendata::Part::MypageLogin
  end
end
