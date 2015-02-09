class Opendata::App
  include Cms::Page::Model
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Contact::Addon::Page
  include Opendata::Addon::Category
  include Opendata::Addon::Area
  include Opendata::Reference::Member
  include SS::Relation::File

  set_permission_name "opendata_apps"

  field :name, type: String
  field :appfilename, type: String
  field :point, type: Integer, default: "0"
  field :text, type: String
  field :tags, type: SS::Extensions::Words
  field :excuted, type: Integer
  field :downloaded, type: Integer

  has_many :points, primary_key: :app_id, class_name: "Opendata::AppPoint",
    dependent: :destroy
  embeds_ids :datasets, class_name: "Opendata::Dataset"
  belongs_to :license, class_name: "Opendata::License"
  belongs_to_file :file

  permit_params :name, :text, :license_id, :dataset_ids, :tags, tags: []

  validates :name, presence: true, length: { maximum: 80 }
  validates :in_file, presence: true, if: ->{ file_id.blank? }
  validates :category_ids, presence: true
  validates :license_id, presence: true

  before_validation :set_appfilename, if: ->{ in_file.present? }
  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "opendata/app") }

  public
    def point_url
      url.sub(/\.html$/, "") + "/point/show.html"
    end

    def point_add_url
      url.sub(/\.html$/, "") + "/point/add.html"
    end

    def point_members_url
      url.sub(/\.html$/, "") + "/point/members.html"
    end

    def contact_present?
      return false if member_id.present?
      super
    end

    def path
      file ? file.path : nil
    end

    def content_type
      file ? file.content_type : nil
    end

    def size
      file ? file.size : nil
    end

    def ss_file_path
      appfile ? appfile.path : nil
    end

    def ss_file_content_type
      appfile ? appfile.content_type : nil
    end

    def ss_file_size
      appfile ? appfile.size : nil
    end

  private
    def validate_filename
      @basename.blank? ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end

    def set_appfilename
      self.appfilename = in_file.original_filename
    end

  class << self
    def sort_options
      [%w(新着順 released), %w(人気順 popular), %w(注目順 attention)]
    end

    def limit_aggregation(pipes, limit)
      return collection.aggregate(pipes) unless limit

      pipes << { "$limit" => limit + 1 }
      aggr = collection.aggregate(pipes)

      def aggr.popped=(bool); @popped = bool end
      def aggr.popped?; @popped.present? end

      if aggr.size > limit
        aggr.pop
        aggr.popped = true
      end
      aggr
    end

    def aggregate_field(name, opts = {})
      pipes = []
      pipes << { "$match" => where({}).selector.merge("#{name}" => { "$exists" => 1 }) }
      pipes << { "$group" => { _id: "$#{name}", count: { "$sum" =>  1 } }}
      pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
      pipes << { "$sort" => { count: -1 } }
      limit_aggregation pipes, opts[:limit]
    end

    def aggregate_array(name, opts = {})
      pipes = []
      pipes << { "$match" => where({}).selector.merge("#{name}" => { "$exists" => 1 }) }
      pipes << { "$project" => { _id: 0, "#{name}" => 1 } }
      pipes << { "$unwind" => "$#{name}" }
      pipes << { "$group" => { _id: "$#{name}", count: { "$sum" =>  1 } }}
      pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
      pipes << { "$sort" => { count: -1 } }
      limit_aggregation pipes, opts[:limit]
    end

    def aggregate_resources(name, opts = {})
      pipes = []
      pipes << { "$match" => where({}).selector.merge("resources.#{name}" => { "$exists" => 1 }) }
      pipes << { "$project" => { _id: 0, "resources.#{name}" => 1 } }
      pipes << { "$unwind" => "$resources" }
      pipes << { "$group" => { _id: "$resources.#{name}", count: { "$sum" =>  1 } }}
      pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
      pipes << { "$sort" => { count: -1 } }
      pipes << { "$limit" => 5 }
      limit_aggregation pipes, opts[:limit]
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      site = params[:site]

      criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?

      criteria = criteria.keyword_in params[:keyword], :name if params[:name].present?

      criteria = criteria.where tags: params[:tag] if params[:tag].present?

      criteria = criteria.where area_ids: params[:area_id].to_i if params[:area_id].present?

      criteria = criteria.where category_ids: params[:category_id].to_i if params[:category_id].present?

      criteria = criteria.where license_id: params[:license_id].to_i if params[:license_id].present?

      criteria
    end
  end
end
