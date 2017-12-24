module Gws::Circular::Sort
  extend ActiveSupport::Concern

  def sort_items
    [
      { key: :updated, order: -1, name: I18n.t('mongoid.attributes.ss/document.updated')},
      { key: :created, order: -1, name: I18n.t('mongoid.attributes.ss/document.created')}
    ]
  end

  def sort_hash(num = 0)
    result = {}
    item = sort_items[num]
    result[item[:key]] = item[:order]
    result
  end

  def sort_options
    sort_items.map.with_index { |item, i| [item[:name], i] }
  end

end
