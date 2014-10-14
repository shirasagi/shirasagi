module Article::Agents::Parts::Page
  class EditController < ApplicationController
    include Cms::PartFilter::Edit
    model Article::Part::Page
  end
end
