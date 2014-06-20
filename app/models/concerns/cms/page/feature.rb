# coding: utf-8
module Cms::Page::Feature
  extend ActiveSupport::Concern
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::Permission
  
  attr_accessor :cur_node, :basename
  
  included do
    index({ site_id: 1, filename: 1 }, { unique: true })
    
    #scope :public, ->{ where(state: "public") }
    
    seqid :id
    field :state, type: String, default: "public"
    field :name, type: String
    field :filename, type: String
    field :depth, type: Integer, metadata: { form: :none }
    field :released, type: DateTime
    field :order, type: Integer, default: 0
    embeds_ids :categories, class_name: "Cms::Node"
    
    permit_params :state, :name, :filename, :basename, :order, category_ids: []
    
    validates :state, presence: true
    validates :name, presence: true, length: { maximum: 80 }
    validates :filename, uniqueness: { scope: :site_id }, length: { maximum: 200 }
    
    before_validation :set_filename
    before_validation :validate_filename
    after_validation :set_depth, if: ->{ filename.present? }
  end
  
  module ClassMethods
    def public
      where(state: "public")
    end
    
    def node(node)
      node ? where(filename: /^#{node.filename}\//, depth: node.depth + 1) : where(depth: 1)
    end
  end
  
  public
    def dirname(basename = nil)
      dir = filename.index("/") ? filename.to_s.sub(/\/[^\/]+$/, "").presence : nil
      basename ? (dir ? "#{dir}/" : "") + basename : dir
    end
    
    def basename
      @basename.presence || filename.to_s.sub(/.*\//, "").presence
    end
    
    def path
      "#{site.path}/#{filename}"
    end
    
    def url
      "#{site.url}#{filename}"
    end
    
    def full_url
      "#{site.full_url}#{filename}"
    end
    
    def json_path
      "#{site.path}/" + filename.sub(/\.html/, ".json")
    end
    
    def json_url
      site.url + filename.sub(/\.html/, ".json")
    end
    
    def public?
      state == "public"
    end
    
    def date
      released || updated || created
    end
    
    def node
      return @cur_node if @cur_node
      return @node if @node
      return nil if depth.to_i <= 1
      
      dirs  = []
      names = File.dirname(filename).split('/')
      names.each {|name| dirs << (dirs.size == 0 ? name : "#{dirs.last}/#{name}") }
      @node = Cms::Node.where(site_id: site_id, :filename.in => dirs).sort(depth: -1).first
    end
    
    def state_options
      [ %w[公開 public], %w[非公開 closed] ]
    end
    
    def order
      value = read_attribute(:order).to_i
      value < 0 ? 0 : value
    end
    
  private
    def fix_extname
      ".html"
    end
    
    def set_filename
      if @cur_node
        self.filename = "#{@cur_node.filename}/#{basename}"
      elsif @basename
        self.filename = basename
      end
    end
    
    def validate_filename
      if @basename
        return errors.add :basename, :empty if @basename.blank?
        errors.add :basename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+(#{fix_extname})?$/
      else
        return errors.add :filename, :empty if filename.blank?
        errors.add :filename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+(#{fix_extname})?$/
      end
      self.filename = filename.sub(/\..*$/, "") + fix_extname if basename.present?
      @basename = filename.sub(/.*\//, "") if @basename
    end
    
    def set_depth
      self.depth = filename.scan("/").size + 1
    end
end
