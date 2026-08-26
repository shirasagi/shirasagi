class Article::Page::ExporterParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user, :cur_node

  attribute :encoding, :string
  attribute :form_id, :string
  attribute :truncate, :string

  validates :encoding, presence: true, inclusion: { in: %w(Shift_JIS UTF-8), allow_blank: true }
  validates :truncate, inclusion: { in: %w(yes no), allow_blank: true }
end
