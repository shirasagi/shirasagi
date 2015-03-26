class Rdf::Prop
  extend SS::Translation
  include SS::Document
  include Rdf::Object

  field :domains, type: Array
  field :ranges, type: Array
  field :sub_property_of, type: Array

  permit_params :domains, :ranges, :sub_property_of
  permit_params domains: []
  permit_params ranges: []

  before_validation :normalize_domains
  before_validation :normalize_ranges

  def usages
    ret = Rdf::Class.vocab(self.vocab).each.select do |rdf_class|
      rdf_class.properties.present?
    end
    uri = self.vocab.uri + self.name
    ret.select do |rdf_class|
      rdf_class.properties.select { |property| property["property"] == uri }.count > 0
    end
  end

  private
    def normalize_domains
      return if domains.blank?
      self.domains = domains.select(&:present?)
    end

    def normalize_ranges
      return if ranges.blank?
      self.ranges = ranges.select(&:present?)
    end
end
