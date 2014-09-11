# coding: utf-8
class Opendata::Dataset
  include Cms::Page::Model
  include Cms::Addon::Body
  include Opendata::Addon::Category
  include Opendata::Addon::DataGroup
  include Opendata::Addon::Area
  include Opendata::Addon::Tag
  include Opendata::Addon::Release

  default_scope ->{ where(route: "opendata/dataset") }
  set_permission_name "opendata_datasets"

  field :point, type: Integer, default: "0"
  field :license, type: String
  field :related_url, type: String
  field :downloaded, type: Integer

  embeds_ids :files, class_name: "Opendata::DatasetFile"

  permit_params :license, :related_url, file_ids: []

  before_save :seq_filename, if: ->{ basename.blank? }

  public
    def generate_file
      true
    end

  private
    def validate_filename
      @basename.blank? ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end

  class << self
    public
      def total_field(key, cond = {})
        collection.aggregate(
          { "$match" => cond.merge(key => { "$exists" => 1 }) },
          #{ "$project" => { _id: 0, "#{key}" => 1 } },
          #{ "$unwind" => "$#{key}" },
          { "$group" => { _id: "$#{key}", count: { "$sum" =>  1 } }},
          { "$project" => { _id: 0, id: "$_id", count: 1 } },
          { "$sort" => { count: -1 } },
          { "$limit" => 5 }
        )
      end

      def total_array_field(key, cond = {})
        collection.aggregate(
          { "$match" => cond.merge(key => { "$exists" => 1 }) },
          { "$project" => { _id: 0, key => 1 } },
          { "$unwind" => "$#{key}" },
          { "$group" => { _id: "$#{key}", count: { "$sum" =>  1 } }},
          { "$project" => { _id: 0, id: "$_id", count: 1 } },
          { "$sort" => { count: -1 } },
          { "$limit" => 5 }
        )
      end
  end
end
