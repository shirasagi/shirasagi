# 書き出し性能履歴の集計結果
module Cms::GenerationReport::Aggregation
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    belongs_to :task, polymorphic: true
    belongs_to :title, class_name: "Cms::GenerationReport::Title"
    field :history_type, type: String
    belongs_to :content, polymorphic: true
    field :content_name, type: String
    field :content_filename, type: String
    field :count, type: Integer
    field :db, type: Float
    field :view, type: Float
    field :elapsed, type: Float
    field :total_db, type: Float
    field :total_view, type: Float
    field :total_elapsed, type: Float
    field :sub_total_db, type: Float
    field :sub_total_view, type: Float
    field :sub_total_elapsed, type: Float
    field :average_db, type: Float
    field :average_view, type: Float
    field :average_elapsed, type: Float
    field :average_total_db, type: Float
    field :average_total_view, type: Float
    field :average_total_elapsed, type: Float
    field :average_sub_total_db, type: Float
    field :average_sub_total_view, type: Float
    field :average_sub_total_elapsed, type: Float
  end

  module ClassMethods
    def search(params = nil)
      all.search_name(params).search_keyword(params)
    end

    def search_name(params = nil)
      return all if params.blank? || params[:name].blank?
      all.search_text params[:name]
    end

    def search_keyword(params = nil)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :history_type, :content_name, :content_filename
    end

    def enum_csv(options)
      drawer = SS::Csv.draw(:export, context: self) do |drawer|
        drawer.column :history_type
        drawer.column :content_id
        drawer.column :content_type
        drawer.column :content_name
        drawer.column :content_filename
        drawer.column :count
        drawer.column :db
        drawer.column :view
        drawer.column :elapsed
        drawer.column :sub_total_db
        drawer.column :sub_total_view
        drawer.column :sub_total_elapsed
        drawer.column :total_db
        drawer.column :total_view
        drawer.column :total_elapsed
        drawer.column :average_db
        drawer.column :average_view
        drawer.column :average_elapsed
        drawer.column :average_sub_total_db
        drawer.column :average_sub_total_view
        drawer.column :average_sub_total_elapsed
        drawer.column :average_total_db
        drawer.column :average_total_view
        drawer.column :average_total_elapsed
      end

      drawer.enum(self.all, options)
    end
  end

  mattr_accessor :class_map, instance_accessor: false, default: {}

  def self.[](title)
    model = Cms::GenerationReport::Aggregation.class_map[title.id.to_s]
    return model if model

    constant_name = "Aggregation#{title.id}"
    model = Class.new do
      extend SS::Translation
      include SS::Document
      include SS::Reference::Site
      include Cms::GenerationReport::Aggregation
      include Cms::SitePermission

      store_in collection: "cms_generation_report_aggregation_#{title.id}"
      set_permission_name "cms_tools", :use

      belongs_to :parent, class_name: "Cms::GenerationReport::#{constant_name}"
      embeds_ids :children, class_name: "Cms::GenerationReport::#{constant_name}"
    end

    Cms::GenerationReport.const_set(constant_name, model)
    model.create_indexes
    Cms::GenerationReport::Aggregation.class_map[title.id.to_s] = model
  end
end
