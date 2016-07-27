class Opendata::Dataset
  include Cms::Page::Model
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Contact::Addon::Page
  include Opendata::Addon::Resource
  include Opendata::Addon::UrlResource
  include Opendata::Addon::Category
  include Opendata::Addon::DatasetGroup
  include Opendata::Addon::Area
  include Opendata::Reference::Member
  include Opendata::Common

  scope :formast_is, ->(word, *fields) {
    where("$and" => [{ "$or" => fields.map { |field| { field => word.to_s } } } ])
  }

  scope :license_is, ->(id, *fields) {
    where("$and" => [{ "$or" => fields.map { |field| { field => id.to_i } } } ])
  }

  set_permission_name "opendata_datasets"

  field :text, type: String
  field :point, type: Integer, default: "0"
  field :tags, type: SS::Extensions::Words
  field :downloaded, type: Integer

  has_many :points, primary_key: :dataset_id, class_name: "Opendata::DatasetPoint",
    dependent: :destroy
  has_many :apps, foreign_key: :dataset_ids, class_name: "Opendata::App::App"
  has_many :ideas, foreign_key: :dataset_ids, class_name: "Opendata::Idea"

  validates :text, presence: true
  validates :category_ids, presence: true

  permit_params :text, :tags, tags: []

  before_save :seq_filename, if: ->{ basename.blank? }
  after_save :on_state_changed, if: ->{ state_changed? }

  default_scope ->{ where(route: "opendata/dataset") }

  public
    def point_url
      get_url(url, "/point.html")
    end

    def point_members_url
      get_url(url, "/point/members.html")
    end

    def dataset_apps_url
      get_url(url, "/apps/show.html")
    end

    def dataset_ideas_url
      get_url(url, "/ideas/show.html")
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

    def on_state_changed
      resources.each do |r|
        r.try(:state_changed)
      end
      url_resources.each do |r|
        r.try(:state_changed)
      end
    end

  class << self
    public
      def to_dataset_path(path)
        suffix = %w(/point.html /point/members.html /apps/show.html /ideas/show.html).find { |suffix| path.end_with? suffix }
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
          { downloaded: -1, _id: -1 }
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

      def aggregate_resources(name, opts = {})
        Opendata::Common.get_aggregate_resources(self, name, opts)
      end

      def get_tag_list(query)
        Opendata::Common.get_tag_list(self, query)
      end

      def get_tag(tag_name)
        Opendata::Common.get_tag(self, tag_name)
      end

      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        site = params[:site]

        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword],
            :name, :text, "resources.name", "resources.filename", "resources.text", "url_resources.name",
                                         "url_resources.filename", "url_resources.text"
        end
        if params[:ids].present?
          criteria = criteria.any_in id: params[:ids].split(/,/)
        end
        if params[:name].present?
          if params[:modal].present?
            words = params[:name].split(/[\s　]+/).uniq.compact.map {|w| /\Q#{w}\E/ }
            criteria = criteria.all_in name: words
          else
            criteria = criteria.keyword_in params[:keyword], :name
          end
        end
        if params[:tag].present?
          criteria = criteria.where tags: params[:tag]
        end
        if params[:area_id].present?
          criteria = criteria.where area_ids: params[:area_id].to_i
        end
        if params[:category_id].present?
          criteria = criteria.where category_ids: params[:category_id].to_i
        end
        if params[:dataset_group].present?
          groups = Opendata::DatasetGroup.site(site).public.search_text(params[:dataset_group])
          groups = groups.pluck(:id).presence || [-1]
          criteria = criteria.any_in dataset_group_ids: groups
        end
        if params[:format].present?
          criteria = criteria.formast_is  params[:format].upcase, "resources.format", "url_resources.format"
        end
        if params[:license_id].present?
          criteria = criteria.license_is  params[:license_id].to_i, "resources.license_id", "url_resources.license_id"
        end

        criteria
      end
  end
end
