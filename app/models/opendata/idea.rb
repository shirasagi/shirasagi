# coding: utf-8
class Opendata::Idea
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  
  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  
  permit_params :state, :name
  
  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }
  
  public
    # dummy
    def allowed?(premit)
      true
    end
    
  class << self
    public
      # def
  end
end
