class Opendata::DatasetGroup
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::Release
  include Cms::Addon::OwnerPermission
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

  def state_options
    [[I18n.t("opendata.state_options.public"), "public"], [I18n.t("opendata.state_options.closed"), "closed"]]
  end

  class << self
    public
      def public
        where(state: "public")
      end

      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        if params[:name].present?
          words = params[:name].split(/[\s　]+/).uniq.compact.map {|w| /\Q#{w}\E/ }
          criteria = criteria.all_in name: words
        end
        if params[:category_id].present?
          criteria = criteria.where category_ids: params[:category_id].to_i
        end

        criteria
      end
  end
end
