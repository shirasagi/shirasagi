module Opendata::Resource::HistoryCsvModel
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    cattr_accessor :csv_headers, instance_accessor: false
    cattr_accessor :model, instance_accessor: false
    attr_accessor :cur_site, :items
  end

  module ClassMethods
    def enum_csv(cur_site, items)
      new(cur_site: cur_site, items: items).enum_csv
    end
  end

  def csv_headers
    self.class.csv_headers.map { |k| self.class.model.t(k) }
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
    terms = self.class.csv_headers.map { |k| to_csv_value(item, k) }
    terms.to_csv
  end

  private

  def to_csv_value(item, key)
    value = item.send(key)
    if value.is_a?(Time) || value.is_a?(Date)
      I18n.l(value)
    elsif value.is_a?(Array)
      value.join("\n")
    else
      value
    end
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end
