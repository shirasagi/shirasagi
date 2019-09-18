module Opendata::ColumnTypesSearcher::Searcher
  class Base
    attr_reader :settings

    def initialize(settings)
      @settings = settings
    end
  end

  class StrictRdfPropertySearcher < Base
    def initialize(settings, opts)
      super(settings)
      @threshold = opts[:threshold]
      @rdf_class = opts[:class] || @settings.rdf_class
    end

    def call
      result = []
      properties = @rdf_class.flattern_properties
      @settings.header_labels.each do |column_names|
        similarities = build_property_similarities(properties, column_names)

        similarity_index = find_max_similarity_one(similarities)
        candidate = similarities[similarity_index] if similarity_index >= 0
        if candidate.present? && candidate[0] >= @threshold
          result << candidate[1]
        else
          result << nil
        end
      end
      result
    end

    def build_property_similarities(properties, column_names)
      similarities = []
      properties.each do |prop|
        max_similarity = 0
        column_names.each do |column_name|
          next if column_name.blank?
          similarity = 1 - Levenshtein.normalized_distance(prop[:names].join(''), column_name)
          max_similarity = similarity if max_similarity < similarity
        end

        similarities << [max_similarity, prop]
      end
      similarities
    end

    def find_max_similarity_one(similarities)
      find = -1
      max_similarity = 0
      similarities.each_with_index do |similarity, index|
        if max_similarity < similarity[0]
          find = index
          max_similarity = similarity[0]
        end
      end
      find
    end
  end

  class FallbackSearcher < Base
    def initialize(searcher, opts)
      super(searcher.settings)
      @searcher = searcher
      @max_rows = opts[:max_rows]
    end

    def call
      results = @searcher.call
      results.each_with_index do |result, index|
        results[index] = {classes: [guess_data_type_at(index)]} if result.blank?
      end
    end

    def guess_data_type_at(column_index)
      tsv = @settings.resource.parse_tsv
      data_types = []
      @settings.header_rows.upto(@max_rows) do |row_index|
        break if tsv.length <= row_index
        value = tsv[row_index][column_index]
        if value.present?
          data_types << guess_data_type(value)
        else
          data_types << ""
        end
      end

      data_types = data_types.uniq.sort
      if data_types.length == 1
        data_types[0] || "xsd:string"
      elsif data_types.length == 2
        if data_types[0].blank?
          data_types[1]
        else
          "xsd:string"
        end
      else
        "xsd:string"
      end
    end

    def guess_data_type(value)
      if /^[-+]?[0-9,]+$/ =~ value
        "xsd:integer"
      elsif /^[-+]?[0-9,]+\.[0-9]+$/ =~ value
        "xsd:decimal"
      else
        "xsd:string"
      end
    end
  end

  def self.call(settings, opts)
    FallbackSearcher.new(StrictRdfPropertySearcher.new(settings, opts), opts).call
  end
end
