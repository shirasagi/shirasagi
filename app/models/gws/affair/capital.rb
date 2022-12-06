class Gws::Affair::Capital
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Affair::CapitalYearly
  include Gws::Addon::Member
  include Gws::Addon::Import::Affair::Capital
  include Gws::Addon::Import::Affair::Capital::Member
  include Gws::Addon::Import::Affair::Capital::Group
  include Gws::SitePermission

  # rubocop:disable Style/ClassVars
  class_variable_set(:@@_member_ids_required, false)
  # rubocop:enable Style/ClassVars

  set_permission_name 'gws_affair_capital_years', :edit

  seqid :id
  field :article_code, type: Integer    # 款
  field :section_code, type: Integer    # 項
  field :subsection_code, type: Integer # 目
  field :item_code, type: Integer       # 節
  field :subitem_code, type: Integer    # 細節
  field :project_code, type: Integer    # 事業コード
  field :detail_code, type: Integer     # 明細

  field :project_name, type: String     # 事業名称
  field :description_name, type: String # 説明名称
  field :item_name, type: String        # 節名称
  field :subitem_name, type: String     # 細節名称

  field :basic_code, type: String       # 款/項/目

  field :name, type: String             # 1款1項1目
  field :basic_code_name, type: String  # 1款1項1目 1-1

  before_validation :set_basic_code

  permit_params :article_code
  permit_params :section_code
  permit_params :subsection_code
  permit_params :item_code
  permit_params :subitem_code
  permit_params :business_code
  permit_params :project_code
  permit_params :detail_code

  permit_params :project_name
  permit_params :description_name
  permit_params :item_name
  permit_params :subitem_name

  validates :article_code, presence: true
  validates :section_code, presence: true
  validates :subsection_code, presence: true
  validates :project_code, presence: true
  validates :detail_code, presence: true

  validates :project_name, presence: true
  validates :description_name, presence: true

  default_scope do
    order_by(
      article_code: 1,
      section_code: 1,
      subsection_code: 1,
      item_code: 1,
      subitem_code: 1,
      project_code: 1,
      detail_code: 1
    )
  end

  index({
    article_code: 1,
    section_code: 1,
    subsection_code: 1,
    item_code: 1,
    subitem_code: 1,
    project_code: 1,
    detail_code: 1
  })
  index({basic_code: 1})

  def set_basic_code
    self.basic_code = "#{article_code}/#{section_code}/#{subsection_code}"

    self.basic_code_name = "#{article_code}#{t(:article_code)}"
    self.basic_code_name += "#{section_code}#{t(:section_code)}"
    self.basic_code_name += "#{subsection_code}#{t(:subsection_code)}"

    self.name = basic_code_name + " #{project_code}-#{detail_code}"
  end

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :no, :name, :remark
      end
      criteria
    end

    def and_date(site, date)
      year = ::Gws::Affair::CapitalYear.and_date(site, date).first
      return self.none unless year
      self.site(site).where(year_id: year.id)
    end
  end
end
