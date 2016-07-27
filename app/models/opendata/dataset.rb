class Opendata::Dataset
  include Cms::Model::Page
  include ::Workflow::Addon::Approver
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
  include Workflow::MemberPermission
  include Opendata::DatasetSearchable
  include Opendata::DatasetTemplateVariables

  set_permission_name "opendata_datasets"

  scope :formast_is, ->(word, *fields) {
    options = fields.extract_options!
    method = options[:method].presence || 'and'
    operator = method == 'and' ? "$and" : "$or"

    where(operator => [{ "$or" => fields.map { |field| { field => word.to_s } } } ])
  }

  scope :license_is, ->(id, *fields) {
    options = fields.extract_options!
    method = options[:method].presence || 'and'
    operator = method == 'and' ? "$and" : "$or"

    where(operator => [{ "$or" => fields.map { |field| { field => id.to_i } } } ])
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

      def format_options
        pipes = []
        pipes << { "$match" => { "route" => "opendata/dataset" } }
        pipes << { "$unwind" => "$resources" }
        pipes << { "$group" => { "_id" => "$resources.format", "count" => { "$sum" => 1 } } }
        self.collection.aggregate(pipes).map do |data|
          format = data["_id"]
          [format, format]
        end
      end
  end
end
