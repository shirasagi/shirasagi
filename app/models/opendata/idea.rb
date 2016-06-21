class Opendata::Idea
  include Cms::Model::Page
  include ::Workflow::Addon::Approver
  include Opendata::Addon::Comment
  include Opendata::Addon::Category
  include Opendata::Addon::Area
  include Opendata::Reference::Member
  include Opendata::Common
  include Cms::Addon::Release
  include Contact::Addon::Page
  include Cms::Addon::RelatedPage
  include Cms::Addon::GroupPermission
  include Workflow::MemberPermission

  set_permission_name "opendata_ideas"

  field :state, type: String, default: "public", overwrite: true
  field :name, type: String, overwrite: true
  field :point, type: Integer, default: "0"
  field :text, type: String
  field :tags, type: SS::Extensions::Words
  field :commented, type: DateTime
  field :total_comment, type: Integer, default: "0"

  field :issue, type: String
  field :data, type: String
  field :note, type: String

  embeds_ids :datasets, class_name: "Opendata::Dataset"
  embeds_ids :apps, class_name: "Opendata::App"
  belongs_to :member, class_name: "Opendata::Member"

  has_many :points, foreign_key: :idea_id, class_name: "Opendata::IdeaPoint",
    dependent: :delete
  has_many :comments, foreign_key: :idea_id, class_name: "Opendata::IdeaComment",
    dependent: :delete

  validates :text, presence: true, length: { maximum: 400 }
  validates :category_ids, presence: true
  validates :state, presence: true

  permit_params :text, :point, :commented, :total_comment, :tags, :dataset_ids, :app_ids, tags: [], dataset_ids: [], app_ids: []
  permit_params :issue, :data, :note

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "opendata/idea") }

  scope :sort_criteria, ->(sort) do
    case sort
    when "attention"
      excludes(commented: nil).order_by(sort_hash(sort))
    else
      order_by(sort_hash(sort))
    end
  end

  public
    def point_url
      get_url(url, "/point.html")
    end

    def point_members_url
      get_url(url, "/point/members.html")
    end

    def comment_url
      get_url(url, "/comment/show.html")
    end

    def comment_add_url
      get_url(url, "/comment/add.html")
    end

    def comment_delete_url
      get_url(url, "/comment/delete.html")
    end

    def related_dataset_url
      get_url(url, "/dataset/show.html")
    end

    def related_app_url
      get_url(url, "/app/show.html")
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

  class << self
    public
      def to_idea_path(path)
        suffix = %w(/point.html /point/members.html /comment/show.html /comment/add.html /comment/delete.html
                    /dataset/show.html /app/show.html).find { |suffix| path.end_with? suffix }
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
          { commented: -1, _id: -1 }
        else
          return { released: -1 } if sort.blank?
          { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
        end
      end

      def aggregate_array(name, opts = {})
        Opendata::Common.get_aggregate_array(self, name, opts)
      end

      def search_params
        params = []
        params << :keyword
        params << :tag
        params << :area_id
        params << :category_id
        params << :option
        params
      end

      def search_options
        %w(all_keywords any_keywords any_conditions).map do |w|
          [I18n.t("opendata.search_options.#{w}"), w]
        end
      end

      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        SEARCH_HANDLERS.each do |handler|
          criteria = send(handler, params, criteria)
        end

        criteria
      end

    private
      SEARCH_HANDLERS = [ :search_keyword, :search_tag, :search_area_id, :search_category_id, :search_poster ].freeze

      def search_keyword(params, criteria)
        if params[:keyword].present?
          option = params[:option].presence
          method = option == 'all_keywords' ? 'and' : 'any'
          criteria = criteria.keyword_in params[:keyword], :name, :text, :issue, :data, :note, method: method
        end
        criteria
      end

      def search_tag(params, criteria)
        if params[:tag].present?
          operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
          criteria = criteria.where(operator => [ tags: params[:tag] ])
        end
        criteria
      end

      def search_area_id(params, criteria)
        if params[:area_id].present?
          operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
          criteria = criteria.where(operator => [ area_ids: params[:area_id].to_i ])
        end
        criteria
      end

      def search_category_id(params, criteria)
        return criteria if params[:category_id].blank?

        operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"

        category_id = params[:category_id].to_i
        category_node = Cms::Node.site(params[:site]).public.where(id: category_id).first
        return criteria if category_node.blank?

        category_ids = [ category_id ]
        category_node.all_children.public.each do |child|
          category_ids << child.id
        end

        criteria.where(operator => [ category_ids: { "$in" => category_ids } ])
      end

      def search_poster(params, criteria)
        if params[:poster].present?
          cond = {}
          cond = { :workflow_member_id.exists => true } if params[:poster] == "member"
          cond = { :workflow_member_id => nil } if params[:poster] == "admin"
          operator = params[:option].presence == 'any_conditions' ? "$or" : "$and"
          criteria = criteria.where(operator => [ cond ])
        end
        criteria
      end
  end
end
