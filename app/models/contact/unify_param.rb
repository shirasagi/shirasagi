class Contact::UnifyParam
  include ActiveModel::Model

  attr_accessor :main_id, :sub_ids

  validates :main_id, presence: true
  validates :sub_ids, presence: true
end
