module Cms::AttachedFiles
  extend ActiveSupport::Concern

  included do
    embeds_many :attached_file_attributes, class_name: "Cms::AttachedFileAttribute"
    before_save :set_attached_file_attributes
  end

  def set_attached_file_attributes
    attached_file_attributes.destroy_all
    attached_files.each do |file|
      attr = self.attached_file_attributes.new
      attr.page_id = id
      attr.initialize_from_file(file)
    end
  end

  module ClassMethods
    def similar_files(file, opts = {})
      return [] if file.blank?

      pipes = []
      pipes << { "$match" => self.criteria.selector }
      pipes << { "$project" => { attached_file_attributes: "$attached_file_attributes" } }
      pipes << { "$unwind" => "$attached_file_attributes" }

      extractor = SS::CsvExtractor.new(file)
      extractor.extract_csv_headers

      name = file.name
      name = opts[:name].unicode_normalize(:nfkc) if opts[:name].present?
      csv_headers = extractor.csv_headers

      match_pipeline = {}
      #match_pipeline["attached_file_attributes.extname"] = extractor.extname

      or_cond = []
      or_cond << { "attached_file_attributes.name" => /#{::Regexp.escape(name)}/ }
      or_cond << { "attached_file_attributes.csv_headers" => csv_headers } if csv_headers.present?
      match_pipeline["$or"] = or_cond

      pipes << { "$match" => match_pipeline }

      self.collection.aggregate(pipes).map do |data|
        Cms::AttachedFileAttribute.new(data["attached_file_attributes"])
      end
    end
  end
end
