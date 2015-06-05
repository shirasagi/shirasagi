class Opendata::App::App
  include Cms::Page::Model
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Contact::Addon::Page
  include Opendata::Addon::Appfile
  include Opendata::Addon::Category
  include Opendata::Addon::Area
  include Opendata::Addon::Dataset
  include Opendata::Reference::Member
  include Opendata::Common

  set_permission_name "opendata_apps"

  field :point, type: Integer, default: "0"
  field :text, type: String
  field :appurl, type: String
  field :tags, type: SS::Extensions::Words
  field :license, type: String
  field :executed, type: Integer

  has_many :points, primary_key: :app_id, class_name: "Opendata::App::AppPoint",
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
      get_url(url, "/point.html")
    end

    def point_members_url
      get_url(url, "/point/members.html")
    end

    def app_ideas_url
      get_url(url, "/ideas/show.html")
    end

    def zip_url
      get_url(url, "/zip")
    end

    def executed_show_url
      get_url(url, "/executed/show.html")
    end

    def executed_add_url
      get_url(url, "/executed/add.html")
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
    def to_app_path(path)
      suffix = %w(/point.html /point/members.html /ideas/show.html /zip /executed/show.html
                  /executed/add.html).find { |suffix| path.end_with? suffix }
      return path if suffix.blank?
      path[0..(path.length - suffix.length - 1)] + '.html'
    end

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

    def aggregate_field(name, opts = {})
      Opendata::Common.get_aggregate_field(self, name, opts)
    end

    def aggregate_array(name, opts = {})
      Opendata::Common.get_aggregate_array(self, name, opts)
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
