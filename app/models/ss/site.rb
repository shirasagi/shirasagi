# coding: utf-8
class SS::Site
  include SS::Document
  
  index({ host: 1 }, { unique: true })
  index({ domains: 1 }, { unique: true })
  
  seqid :id
  field :name, type: String
  field :host, type: String
  field :domains, type: SS::Extensions::Words
  
  permit_params :name, :host, :domains
  
  belongs_to :group, class_name: "SS::Group"
  has_many :pages, class_name: "Cms::Page", dependent: :destroy
  has_many :nodes, class_name: "Cms::Node", dependent: :destroy
  has_many :parts, class_name: "Cms::Part", dependent: :destroy
  has_many :layouts, class_name: "Cms::Layout", dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 40 }
  validates :host, uniqueness: true, presence: true, length: { minimum: 3, maximum: 16 }
  
  def domain
    domains[0]
  end
  
  def path
    "#{self.class.root}/" + host.split(//).join("/") + "/_"
  end
  
  def url
    domain.index("/") ? domain.sub(/^.*?\//, "/") : "/"
  end
  
  def full_url
    "http://#{domain}/".sub(/\/+$/, "/")
  end
  
  class << self
    def root
      "#{Rails.root}/public/sites"
    end
  end
end
