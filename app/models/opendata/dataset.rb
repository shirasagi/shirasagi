class Opendata::Dataset
  include Cms::Page::Model
  include Cms::Addon::Release
  include Contact::Addon::Page
  include Opendata::Addon::Resource
  include Opendata::Addon::Category
  include Opendata::Addon::DatasetGroup
  include Opendata::Addon::Area
  include Opendata::Reference::Member

  set_permission_name "opendata_datasets"

  field :text, type: String
  field :point, type: Integer, default: "0"
  field :tags, type: SS::Extensions::Words
  field :downloaded, type: Integer

  has_many :points, primary_key: :dataset_id, class_name: "Opendata::DatasetPoint",
    dependent: :destroy

  validates :text, presence: true
  validates :category_ids, presence: true

  permit_params :text, :tags, tags: []

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "opendata/dataset") }

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

      def aggregate_field(name)
        pipes = []
        pipes << { "$match" => where({}).selector.merge("#{name}" => { "$exists" => 1 }) }
        pipes << { "$group" => { _id: "$#{name}", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
        pipes << { "$sort" => { count: -1 } }
        pipes << { "$limit" => 5 }
        collection.aggregate(pipes)
      end

      def aggregate_array(name)
        pipes = []
        pipes << { "$match" => where({}).selector.merge("#{name}" => { "$exists" => 1 }) }
        pipes << { "$project" => { _id: 0, "#{name}" => 1 } }
        pipes << { "$unwind" => "$#{name}" }
        pipes << { "$group" => { _id: "$#{name}", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
        pipes << { "$sort" => { count: -1 } }
        pipes << { "$limit" => 5 }
        collection.aggregate(pipes)
      end

      def aggregate_resources(name, cond = {})
        pipes = []
        pipes << { "$match" => where({}).selector.merge("resources.#{name}" => { "$exists" => 1 }) }
        pipes << { "$project" => { _id: 0, "resources.#{name}" => 1 } }
        pipes << { "$unwind" => "$resources" }
        pipes << { "$group" => { _id: "$resources.#{name}", count: { "$sum" =>  1 } }}
        pipes << { "$project" => { _id: 0, id: "$_id", count: 1 } }
        pipes << { "$sort" => { count: -1 } }
        pipes << { "$limit" => 5 }
        collection.aggregate(pipes)
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
        if params[:dataset_group].present?
          groups = Opendata::DatasetGroup.site(site).public.search_text(params[:dataset_group])
          groups = groups.pluck(:id).presence || [-1]
          criteria = criteria.any_in dataset_group_ids: groups
        end
        if params[:format].present?
          criteria = criteria.where "resources.format" => params[:format].upcase
        end
        if params[:license_id].present?
          criteria = criteria.where "resources.license_id" => params[:license_id].to_i
        end

        criteria
      end
  end
end
