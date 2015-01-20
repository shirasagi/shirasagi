class Opendata::Idea
  include Cms::Page::Model
  include Opendata::Addon::Category
  include Opendata::Addon::Area
  include Opendata::Addon::Dataset
  include Opendata::Addon::App
  include Opendata::Reference::Member

  set_permission_name "opendata_ideas"

  field :state, type: String, default: "public"
  field :name, type: String
  field :point, type: Integer, default: "0"
  field :text, type: String
  field :tags, type: SS::Extensions::Words

  belongs_to :dataset, class_name: "Opendata::Dataset"
  belongs_to :app, class_name: "Opendata::App"

  has_many :points, primary_key: :idea_id, class_name: "Opendata::IdeaPoint",
    dependent: :destroy
  has_many :comments, primary_key: :idea_id, class_name: "Opendata::IdeaComment",
    dependent: :destroy

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }

  permit_params :state, :name, :dataset_id, :app_id, :text, :point, :tags, tags: []

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "opendata/idea") }

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

    def comment_url
      url.sub(/\.html$/, "") + "/comment/show.html"
    end

    def comment_add_url
      url.sub(/\.html$/, "") + "/comment/add.html"
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
        logger.warn pipes
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
