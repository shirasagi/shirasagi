module Opendata::Parts::MypageLogin
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Opendata::Part::MypageLogin
  end
end
