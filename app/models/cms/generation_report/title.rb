class Cms::GenerationReport::Title
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_tools", :use

  field :name, type: String

  belongs_to :task, polymorphic: true
  field :task_started, type: DateTime
  field :task_closed, type: DateTime
  field :sha256_hash, type: String

  field :generation_type, type: String

  after_destroy :destroy_all_histories
  after_destroy :destroy_all_aggregations

  class << self
    def search(params = nil)
      all.search_name(params).search_keyword(params)
    end

    def search_name(params = nil)
      return all if params.blank? || params[:name].blank?
      all.search_text params[:name]
    end

    def search_keyword(params = nil)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :name, :memo
    end
  end

  private

  def destroy_all_histories
    Cms::GenerationReport::History[self].collection.drop
  end

  def destroy_all_aggregations
    Cms::GenerationReport::Aggregation[self].collection.drop
  end
end
