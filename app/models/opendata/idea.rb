class Opendata::Idea
  include Cms::Page::Model
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Contact::Addon::Page
  include Opendata::Addon::Comment
  include Opendata::Addon::Category
  include Opendata::Addon::Area
  include Opendata::Reference::Member

  set_permission_name "opendata_ideas"

  field :state, type: String, default: "public", overwrite: true
  field :name, type: String, overwrite: true
  field :point, type: Integer, default: "0"
  field :text, type: String
  field :tags, type: SS::Extensions::Words
  field :commented, type: DateTime
  field :total_comment, type: Integer, default: "0"

  embeds_ids :datasets, class_name: "Opendata::Dataset"
  embeds_ids :apps, class_name: "Opendata::App"
  belongs_to :member, class_name: "Opendata::Member"

  has_many :points, primary_key: :idea_id, class_name: "Opendata::IdeaPoint",
    dependent: :destroy
  has_many :comments, primary_key: :idea_id, class_name: "Opendata::IdeaComment",
    dependent: :destroy

  validates :text, presence: true, length: { maximum: 400 }
  validates :category_ids, presence: true
  validates :state, presence: true

  permit_params :text, :point, :commented, :total_comment, :tags, :dataset_ids, :app_ids, tags: [], dataset_ids: [], app_ids: []

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
      url.sub(/\.html$/, "") + "/point.html"
    end

    def point_members_url
      url.sub(/\.html$/, "") + "/point/members.html"
    end

    def comment_url
      url.sub(/\.html$/, "") + "/comment/show.html"
    end

    def comment_add_url
      url.sub(/\.html$/, "") + "/comment/add.html"
    end

    def comment_delete_url
      url.sub(/\.html$/, "") + "/comment/delete.html"
    end

    def related_dataset_url
      url.sub(/\.html$/, "") + "/dataset/show.html"
    end

    def related_app_url
      url.sub(/\.html$/, "") + "/app/show.html"
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
        [%w(新着順 released), %w(人気順 popular), %w(注目順 attention)]
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

        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword],
            :name, :text, "resources.name", "resources.filename", "resources.text"
        end
        if params[:name].present?
          criteria = criteria.keyword_in params[:keyword], :name
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

        criteria
      end
  end
end
