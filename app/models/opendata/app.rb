class Opendata::App
  include Cms::Page::Model
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Contact::Addon::Page
  include Opendata::Addon::Appfile
  include Opendata::Addon::Category
  include Opendata::Addon::Area
  include Opendata::Addon::Dataset
  include Opendata::Reference::Member

  set_permission_name "opendata_apps"

  field :point, type: Integer, default: "0"
  field :text, type: String
  field :appurl, type: String
  field :tags, type: SS::Extensions::Words
  field :license, type: String
  field :executed, type: Integer

  has_many :points, primary_key: :app_id, class_name: "Opendata::AppPoint",
    dependent: :destroy
  embeds_ids :datasets, class_name: "Opendata::Dataset"
  has_many :ideas, primary_key: :app_id, class_name: "Opendata::Idea"

  permit_params :text, :appurl, :license, :dataset_ids, :tags, tags: []

  validates :text, presence: true
  validates :category_ids, presence: true
  validates :license, presence: true
  validate :validate_appurl

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

    def app_ideas_url
      url.sub(/\.html$/, "") + "/ideas/show.html"
    end

    def zip_url
      url.sub(/\.html$/, "") + "/zip"
    end

    def executed_show_url
      url.sub(/\.html$/, "") + "/executed/show.html"
    end

    def executed_add_url
      url.sub(/\.html$/, "") + "/executed/add.html"
    end

    def contact_present?
      return false if member_id.present?
      super
    end

  private
    def validate_filename
      @basename.blank? ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end

    def validate_appurl
      if self.appurl.present?
        if self.appfiles.present?
          errors.add :appurl, "はアプリのファイルを登録している場合、入力できません。"
          return
        end
      end
    end

  class << self
    def sort_options
      [%w(新着順 released), %w(人気順 popular), %w(注目順 attention)]
    end

    def sort_hash(sort)
      case sort
      when "released"
        { released: -1, _id: -1 }
      when "popular"
        { point: -1, _id: -1 }
      when "attention"
        { executed: -1, _id: -1 }
      else
        return { released: -1 } if sort.blank?
        { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
      end
    end

    def limit_aggregation(pipes, limit)
      return collection.aggregate(pipes) unless limit

      pipes << { "$limit" => limit + 1 }
      aggr = collection.aggregate(pipes)

      def aggr.popped=(bool)
        @popped = bool
      end

      def aggr.popped?
        @popped.present?
      end

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

    def get_tag_list(query)
      pipes = []
      pipes << { "$match" => where({}).selector.merge("tags" => { "$exists" => 1 }) }
      pipes << { "$project" => { _id: 0, "tags" => 1 } }
      pipes << { "$unwind" => "$tags" }
      pipes << { "$group" => { _id: "$tags", count: { "$sum" =>  1 } }}
      pipes << { "$project" => { _id: 0, name: "$_id", count: 1 } }
      pipes << { "$sort" => { name: 1 } }
      collection.aggregate(pipes)
    end

    def get_tag(tag_name)
      pipes = []
      pipes << { "$match" => where({}).selector.merge("tags" => { "$exists" => 1 }) }
      pipes << { "$project" => { _id: 0, "tags" => 1 } }
      pipes << { "$unwind" => "$tags" }
      pipes << { "$group" => { _id: "$tags", count: { "$sum" =>  1 } }}
      pipes << { "$project" => { _id: 0, name: "$_id", count: 1 } }
      pipes << { "$match" => { name: tag_name }}
      pipes << { "$sort" => { name: 1 } }
      collection.aggregate(pipes)
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      site = params[:site]

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword],
          :name, :text, "appfiles.name", "appfiles.filename", "appfiles.text"
      end

      criteria = criteria.keyword_in params[:keyword], :name if params[:name].present?

      criteria = criteria.where tags: params[:tag] if params[:tag].present?

      criteria = criteria.where area_ids: params[:area_id].to_i if params[:area_id].present?

      criteria = criteria.where category_ids: params[:category_id].to_i if params[:category_id].present?

      criteria = criteria.where license: params[:license] if params[:license].present?

      criteria
    end
  end
end
