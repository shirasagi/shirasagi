# coding: utf-8
class Cms::Role
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  
  cattr_accessor(:permission_names) { [] }
  
  seqid :id
  field :name, type: String
  field :permission_level, type: Integer, default: 1
  field :permissions, type: SS::Extensions::Array
  permit_params :name, :permission_level, permissions: []
  
  validates :name, presence: true, length: { maximum: 80 }
  validates :permission_level, presence: true
  #validates :permissions, presence: true
  
  def permission_level_options
    [%w[1 1], %w[2 2], %w[3 3]]
  end
  
  class << self
    def permission(name)
      self.permission_names << [name, name.to_s]
    end
  end
end
