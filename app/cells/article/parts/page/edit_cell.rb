module Article::Parts::Page
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Article::Part::Page
  end
end
