class Opendata::License
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include SS::Relation::File
  include Cms::Addon::GroupPermission

  set_permission_name :opendata_datasets

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :related_url, type: String
  field :order, type: Integer, default: 0

  belongs_to_file :file

  permit_params :state, :name, :related_url, :order, file_ids: []

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }
  validates :in_file, presence: true, if: ->{ file_id.blank? }

  def state_options
    [[I18n.t("opendata.state_options.public"), "public"], [I18n.t("opendata.state_options.closed"), "closed"]]
  end

  class << self
    public
      def and_public
        where(state: "public")
      end

      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
        criteria
      end
  end
end
