class Cms::FormDb::ImportLog
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Site

  attr_accessor :cur_user

  field :data, type: String

  belongs_to :db, class_name: 'Cms::FormDb'
  belongs_to :form, class_name: 'Cms::Form'
  belongs_to :node, class_name: 'Article::Node::Page'

  permit_params :db_id, :form_id, :node_id

  validates :db_id, presence: true
  validates :form_id, presence: true
  validates :node_id, presence: true
end
