class Ads::AccessLog
  include Mongoid::Document
  include SS::Reference::Site

  #index({ site_id: 1, node_id: 1, date: -1 })

  field :node_id, type: Integer
  field :link_url, type: String
  field :date, type: Date
  field :count, type: Integer, default: 0

  validates :site_id, presence: true
  validates :node_id, presence: true
  validates :link_url, presence: true
  validates :date, presence: true
end
