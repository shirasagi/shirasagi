# coding: utf-8
class SS::Group
  include SS::Document
  
  seqid :id
  field :name, type: String
  permit_params :name
  
  validates :name, presence: true, length: { maximum: 80 }
end
