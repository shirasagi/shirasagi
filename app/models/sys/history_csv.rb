class Sys::HistoryCsv
  include ActiveModel::Model

  attr_accessor :cur_site, :items

  CSV_HEADERS = %i[
    created user_label target_label action url session_id request_id
  ].freeze

  class << self
    def enum_csv(cur_site, items)
      new(cur_site: cur_site, items: items).enum_csv
    end
  end

  def csv_headers
    CSV_HEADERS.map { |k| History::Log.t(k) }
  end

  def enum_csv(opts = {})
    Enumerator.new do |y|
      y << encode_sjis(csv_headers.to_csv)
      items.each do |item|
        y << encode_sjis(to_csv(item))
      end
    end
  end

  def to_csv(item)
    terms = []
    CSV_HEADERS.each do |k|
      if k == :created
        terms << I18n.l(item.created)
      elsif k == :updated_field_names
        names = item.updated_field_names
        terms << names.join(',')
      else
        terms << item.send(k)
      end
    end
    terms.to_csv
  end

  private

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end
