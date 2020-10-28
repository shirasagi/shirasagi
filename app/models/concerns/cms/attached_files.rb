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
    def similar_files(in_file, opts = {})
      return [] unless in_file

      pipes = []
      pipes << { "$match" => self.criteria.selector }
      pipes << { "$project" => { attached_file_attributes: "$attached_file_attributes" } }
      pipes << { "$unwind" => "$attached_file_attributes" }

      extractor = SS::CsvExtractor.new(in_file)
      extractor.extract_csv_headers

      filename = extractor.filename
      filename = opts[:filename] if opts[:filename].present?

      extname = extractor.extname
      basename = filename.sub(/\.#{extname}$/, "").unicode_normalize(:nfkc)
      csv_headers = extractor.csv_headers

      match_pipeline = {}
      #match_pipeline["attached_file_attributes.extname"] = extname

      or_cond = []
      #or_cond << { "attached_file_attributes.filename" => /#{::Regexp.escape(basename)}/ }
      or_cond << { "attached_file_attributes.name" => /#{::Regexp.escape(basename)}/ }
      or_cond << { "attached_file_attributes.csv_headers" => csv_headers } if csv_headers.present?
      match_pipeline["$or"] = or_cond

      pipes << { "$match" => match_pipeline }

      self.collection.aggregate(pipes).map do |data|
        Cms::AttachedFileAttribute.new(data["attached_file_attributes"])
      end
    end
  end
end
