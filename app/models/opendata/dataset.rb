# coding: utf-8
class Opendata::Dataset
  include Cms::Page::Model
  include Opendata::Addon::Resource
  include Opendata::Addon::Category
  include Opendata::Addon::DataGroup
  include Opendata::Addon::Area
  include Opendata::Addon::Tag
  include Opendata::Addon::Release
  include Opendata::Reference::Member

  set_permission_name "opendata_datasets"

  field :text, type: String
  field :point, type: Integer, default: "0"
  field :license, type: String
  field :related_url, type: String
  field :downloaded, type: Integer

  validates :license, presence: true
  validates :category_ids, presence: true

  permit_params :text, :license, :related_url, file_ids: []

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "opendata/dataset") }

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
        key = key.to_s
        pre = key.sub(/\..*/, '')

        pipes = []
        pipes << { "$match" => cond.merge(key => { "$exists" => 1 }) }

        if pre.pluralize == pre
          pipes << { "$project" => { _id: 0, key => 1 } }
          pipes << { "$unwind" => "$#{pre}" }
        end

        pipes << { "$group" => { _id: "$#{key}", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
        pipes << { "$sort" => { count: -1 } }
        pipes << { "$limit" => 5 }

        collection.aggregate(pipes)
      end
  end
end
