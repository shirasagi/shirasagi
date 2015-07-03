class Opendata::Dataset
  include Cms::Model::Page
  include Opendata::Addon::Resource
  include Opendata::Addon::UrlResource
  include Opendata::Addon::Category
  include Opendata::Addon::Area
  include Opendata::Addon::DatasetGroup
  include Opendata::Reference::Member
  include Opendata::Common
  include Cms::Addon::Release
  include Contact::Addon::Page
  include Cms::Addon::RelatedPage
  include Cms::Addon::GroupPermission

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
  has_many :apps, foreign_key: :dataset_ids, class_name: "Opendata::App"
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
        [
          [I18n.t("opendata.sort_options.released"), "released"],
          [I18n.t("opendata.sort_options.popular"), "popular"],
          [I18n.t("opendata.sort_options.attention"), "attention"]
        ]
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
        [ :search_keyword, :search_ids, :search_name, :search_tag, :search_area_id, :search_category_id,
          :search_dataset_group, :search_format, :search_license_id, ].each do |m|
          criteria = send(m, params, criteria)
        end

        criteria
      end

    private
      def search_keyword(params, criteria)
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword],
                       :name, :text, "resources.name", "resources.filename", "resources.text",
                       "url_resources.name", "url_resources.filename", "url_resources.text"
        end
        criteria
      end

      def search_ids(params, criteria)
        if params[:ids].present?
          criteria = criteria.any_in id: params[:ids].split(/,/)
        end
        criteria
      end

      def search_name(params, criteria)
        if params[:name].present?
          if params[:modal].present?
            words = params[:name].split(/[\s　]+/).uniq.compact.map {|w| /#{Regexp.escape(w)}/i }
            criteria = criteria.all_in name: words
          else
            criteria = criteria.keyword_in params[:keyword], :name
          end
        end
        criteria
      end

      def search_tag(params, criteria)
        if params[:tag].present?
          criteria = criteria.where tags: params[:tag]
        end
        criteria
      end

      def search_area_id(params, criteria)
        if params[:area_id].present?
          criteria = criteria.where area_ids: params[:area_id].to_i
        end
        criteria
      end

      def search_category_id(params, criteria)
        if params[:category_id].present?
          criteria = criteria.where category_ids: params[:category_id].to_i
        end
        criteria
      end

      def search_dataset_group(params, criteria)
        site = params[:site]
        if params[:dataset_group].present?
          groups = Opendata::DatasetGroup.site(site).public.search_text(params[:dataset_group])
          groups = groups.pluck(:id).presence || [-1]
          criteria = criteria.any_in dataset_group_ids: groups
        end
        criteria
      end

      def search_format(params, criteria)
        if params[:format].present?
          criteria = criteria.formast_is  params[:format].upcase, "resources.format", "url_resources.format"
        end
        criteria
      end

      def search_license_id(params, criteria)
        if params[:license_id].present?
          criteria = criteria.license_is  params[:license_id].to_i, "resources.license_id", "url_resources.license_id"
        end
        criteria
      end
  end
end
