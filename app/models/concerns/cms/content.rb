module Cms::Content
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Cms::TemplateVariable
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::GroupPermission
  include Cms::Addon::CheckLinks

  attr_accessor :cur_node, :basename
  attr_accessor :serve_static_relation_files

  included do
    seqid :id
    field :state, type: String, default: "public"
    field :name, type: String
    field :index_name, type: String
    field :filename, type: String
    field :depth, type: Integer
    field :order, type: Integer, default: 0
    field :released, type: DateTime
    field :first_released, type: DateTime
    field :md5, type: String

    permit_params :state, :name, :index_name, :filename, :basename, :order, :released, :route

    validates :state, presence: true
    validates :name, presence: true, length: { maximum: 80 }
    validates :filename, uniqueness: { scope: :site_id }, length: { maximum: 200 }
    validates :released, datetime: true

    after_validation :set_released, if: -> { public? }
    before_validation :set_filename
    before_validation :validate_filename
    after_validation :set_depth, if: ->{ filename.present? }

    scope :filename, ->(name) { where filename: name.sub(/^\//, "") }
    scope :node, ->(node) {
      node ? where(filename: /^#{node.filename}\//, depth: node.depth + 1) : where(depth: 1)
    }
    scope :and_public, ->(date = nil) {
      if date.nil?
        where state: "public"
      else
        date = date.dup
        where("$and" => [
          { "$or" => [ { state: "public", :released.lte => date }, { :release_date.lte => date } ] },
          { "$or" => [ { close_date: nil }, { :close_date.gt => date } ] },
        ])
      end
    }
  end

  module ClassMethods
    def split_path(path)
      last = nil
      dirs = path.split('/').map { |n| last = last ? "#{last}/#{n}" : n }
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :filename, :html
      end
      criteria
    end
  end

  def name_for_index
    index_name || name
  end

  def basename
    @basename.presence || filename.to_s.sub(/.*\//, "").presence
  end

  def dirname(basename = nil)
    if filename.present?
      dir = filename.index("/") ? filename.to_s.sub(/\/[^\/]+$/, "").presence : nil
    end
    basename ? (dir ? "#{dir}/" : "") + basename : dir
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
    "#{site.path}/" + filename.sub(/(\/|\.html)?$/, ".json")
  end

  def json_url
    site.url + filename.sub(/(\/|\.html)?$/, ".json")
  end

  def date
    updated || created
  end

  def public?
    state == "public"
  end

  def public_node?
    return true unless dirname
    Cms::Node.where(site_id: site_id).in_path(dirname).ne(state: "public").empty?
  end

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def state_options
    [
      [I18n.t('ss.options.state.public'), 'public'],
      [I18n.t('ss.options.state.closed'), 'closed'],
    ]
  end

  def state_private_options
    [[I18n.t('ss.options.state.ready'), 'ready']]
  end

  def status
    state
  end

  def status_options
    state_options
  end

  def parent
    return @cur_node if @cur_node
    return @parent unless @parent.nil?
    return @parent = false if depth == 1 || filename !~ /\//

    path = File.dirname(filename)
    @parent = Cms::Node.where(site_id: site_id).in_path(path).sort(depth: -1).first
  end

  def becomes_with_route(name = nil)
    # be careful, Cms::Layout does not respond to route
    name ||= route if respond_to?(:route)
    return self unless name
    klass = name.camelize.constantize rescue nil
    return self unless klass

    item = klass.new
    item.instance_variable_set(:@new_record, nil) unless new_record?
    instance_variables.each { |k| item.instance_variable_set k, instance_variable_get(k) }
    item
  end

  def serve_static_file?
    SS.config.cms.serve_static_pages
  end

  def serve_static_relation_files?
    return false unless serve_static_file?
    return true if @serve_static_relation_files.nil?
    @serve_static_relation_files == true
  end

  private

  def set_filename
    if @cur_node
      self.filename = "#{@cur_node.filename}/#{basename}"
    elsif @basename
      self.filename = basename
    end
  end

  def set_depth
    self.depth = filename.scan("/").size + 1
  end

  def set_released
    now = Time.zone.now
    self.released ||= now
    self.first_released ||= now
  end

  def fix_extname
    nil
  end

  def validate_filename
    if @basename
      return errors.add :basename, :empty if @basename.blank?
      errors.add :basename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+(#{fix_extname})?$/
      errors.add :basename, :invalid if basename !~ /^[\w\-]+(#{fix_extname})?$/
    else
      return errors.add :filename, :empty if filename.blank?
      errors.add :filename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+(#{fix_extname})?$/
    end

    self.filename = filename.sub(/\..*$/, "") + fix_extname if fix_extname && basename.present?
    @basename = filename.sub(/.*\//, "") if @basename
  end
end
