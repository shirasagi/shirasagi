class Cms::Column::SelectPage < Cms::Column::Base
  field :place_holder, type: String
  embeds_ids :pages, class_name: 'Cms::Page'
  permit_params page_ids: []

  def select_options
    ordered_pages.map { |page| [page.name, page.id] }
  end
end
