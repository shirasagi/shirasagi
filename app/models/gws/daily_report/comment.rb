class Gws::DailyReport::Comment
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include SS::Addon::Markdown
  include Gws::Addon::History

  seqid :id
  field :body, type: String
  field :report_key, type: String

  belongs_to :report, class_name: 'Gws::DailyReport::Report'
  belongs_to :column, class_name: 'Cms::Column::Base'

  permit_params :body

  validates :body, presence: true
  validates :report_id, presence: true
end
