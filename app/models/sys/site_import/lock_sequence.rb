class Sys::SiteImport::LockSequence
  include Mongoid::Document

  field :ref_collection_name, type: String
  field :value, type: Integer

  validates :ref_collection_name, presence: true
  validates :value, presence: true
end
