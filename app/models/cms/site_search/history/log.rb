class Cms::SiteSearch::History::Log
  include SS::Document
  include SS::Reference::Site

  store_in_repl_master
  index({ created: -1 })

  field :query, type: Hash
  field :remote_addr, type: String
  field :user_agent, type: String

  validates :query, presence: true

  default_scope -> { order_by(created: -1) }
end
