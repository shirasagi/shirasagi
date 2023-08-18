class Gws::DailyReport::Comment
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :report_key, type: String
  field :body, type: String

  belongs_to :report, class_name: 'Gws::DailyReport::Report'
  belongs_to :column, class_name: 'Cms::Column::Base'

  permit_params :body

  before_validation :set_column_id

  validates :report_id, presence: true
  validates :body, presence: true

  class << self
    def search(params)
      criteria = all
      criteria = criteria.search_keyword(params)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in(params[:keyword], :body)
    end
  end

  private

  def set_column_id
    return if %w(small_talk column_value_ids).include?(report_key)

    self.column_id = report_key
    self.report_key = 'column_value_ids'
  end
end
