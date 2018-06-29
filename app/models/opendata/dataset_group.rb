class Opendata::DatasetGroup
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::TemplateVariable
  include Cms::Addon::Release
  include Cms::Addon::GroupPermission
  include Opendata::Addon::Category

  set_permission_name :opendata_datasets

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :order, type: Integer

  permit_params :state, :name, :order, file_ids: []

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }
  validates :category_ids, presence: true

  def url
    node = Opendata::Node::SearchDataset.site(site).and_public.first
    raise "dataset search is disabled since Opendata::Node::SearchDataset is not registered" unless node
    ActionDispatch::Http::URL.path_for(path: node.url, params: { "s[dataset_group_id]" => id })
  end

  def state_options
    [[I18n.t("opendata.state_options.public"), "public"], [I18n.t("opendata.state_options.closed"), "closed"]]
  end

  def sort_options
    self.class.sort_options
  end

  class << self
    def and_public
      where(state: "public")
    end

    def sort_options
      [
        [I18n.t('cms.options.sort.name'), 'name'],
        [I18n.t('cms.options.sort.created'), 'created'],
        [I18n.t('cms.options.sort.updated_1'), 'updated -1'],
      ]
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        words = params[:name].split(/[\s　]+/).uniq.compact.map { |w| /\Q#{::Regexp.escape(w)}\E/ }
        criteria = criteria.all_in name: words
      end
      if params[:category_id].present?
        criteria = criteria.where category_ids: params[:category_id].to_i
      end

      criteria
    end
  end
end
