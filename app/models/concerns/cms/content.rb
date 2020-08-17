module Cms::Content
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Cms::TemplateVariable
  include SS::Liquidization
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::GroupPermission
  include Cms::Addon::CheckLinks
  include Fs::FilePreviewable
  include History::Addon::Trash

  attr_accessor :cur_node, :basename

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
    validates :name, presence: true
    validates :filename, uniqueness: { scope: :site_id }, length: { maximum: 200 }
    validates :released, datetime: true
    after_validation :set_released, if: -> { public? }
    before_validation :set_filename
    before_validation :validate_filename
    after_validation :set_depth, if: ->{ filename.present? }

    validate :validate_name, if: ->{ name.present? }

    after_destroy :remove_private_dir

    scope :filename, ->(name) { where filename: name.sub(/^\//, "") }
    scope :node, ->(node, target = nil) {
      if target == 'descendant'
        node ? where(filename: /^#{::Regexp.escape(node.filename)}\//) : where({})
      else #current
        node ? where(filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1) : where(depth: 1)
      end
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

    liquidize do
      export :id
      export :name
      export :index_name
      export :url
      export :full_url
      export :basename
      export :filename
      export :order
      export :date
      export :released
      export :updated
      export :created
      export :parent do
        p = self.parent
        p == false ? nil : p
      end
      export :css_class do |context|
        issuer = context.registers[:cur_part] || context.registers[:cur_node]
        template_variable_handler_class("class", issuer)
      end
      export :new? do |context|
        issuer = context.registers[:cur_part] || context.registers[:cur_node]
        issuer.respond_to?(:in_new_days?) && issuer.in_new_days?(self.date)
      end
      export :current? do |context|
        # ApplicationHelper#current_url?
        cur_path = context.registers[:cur_path]
        next false if cur_path.blank?

        current = cur_path.sub(/\?.*/, "")
        next false if current.delete("/").blank?
        next true if self.url.sub(/\/index\.html$/, "/") == current.sub(/\/index\.html$/, "/")
        next true if current =~ /^#{::Regexp.escape(url)}(\/|\?|$)/

        false
      end
    end
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

    def public_list(opts = {})
      site = opts[:site]
      parent_item = opts[:node] || opts[:part] || opts[:parent]
      date = opts[:date]

      criteria = self.all

      # condition_hash
      if parent_item && parent_item.respond_to?(:condition_hash)
        ids = self.unscoped.where(parent_item.condition_hash).distinct(:id)
        return criteria.none if ids.blank?

        criteria = criteria.in(id: ids)
        criteria = criteria.hint({ _id: 1 })

        # criteria.count does not use hint
        def criteria.count(options = {}, &block)
          options = options.symbolize_keys
          options[:hint] = { _id: 1 }
          super(options, &block)
        end
      end

      # site and_public
      criteria = criteria.site(site) if site
      criteria = criteria.and_public(date)

      criteria
    end

    def private_root
      "#{SS::Application.private_root}/#{self.collection_name}"
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

  def private_dir
    return if new_record?
    self.class.private_root + "/" + id.to_s.split(//).join("/") + "/_"
  end

  def private_file(basename)
    return if new_record?
    "#{private_dir}/#{basename}"
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

    @parent ||= begin
      path = File.dirname(filename)
      Cms::Node.where(site_id: site_id).in_path(path).order_by(depth: -1).to_a.first
    end
  end

  def becomes_with_route(name = nil)
    # be careful, Cms::Layout does not respond to route
    name ||= route if respond_to?(:route)
    return self unless name
    klass = name.camelize.constantize rescue nil
    return self unless klass

    becomes_with(klass)
  end

  def serve_static_file?
    SS.config.cms.serve_static_pages
  end

  def node_target_options
    %w(current descendant).map { |m| [ I18n.t("cms.options.node_target.#{m}"), m ] }
  end

  def file_previewable?(file, user:, member:)
    return false unless public?
    return false unless public_node?
    return false if try(:for_member_enabled?) && member.blank?
    true
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
      errors.add :basename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+(#{::Regexp.escape(fix_extname || "")})?$/
      errors.add :basename, :invalid if basename !~ /^[\w\-]+(#{::Regexp.escape(fix_extname || "")})?$/
    else
      return errors.add :filename, :empty if filename.blank?
      errors.add :filename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+(#{::Regexp.escape(fix_extname || "")})?$/
    end

    self.filename = filename.sub(/\..*$/, "") + fix_extname if fix_extname && basename.present?
    @basename = filename.sub(/.*\//, "") if @basename
  end

  def create_history_trash
    backup = History::Trash.new
    backup.ref_coll = collection_name
    backup.ref_class = self.becomes_with_route.class.to_s
    backup.data = attributes
    backup.data.delete(:lock_until)
    backup.data.delete(:lock_owner_id)
    backup.site = self.site
    backup.user = @cur_user
    backup.save
  end

  def validate_name
    max_name_length = @cur_site.try(:max_name_length).to_i

    return if max_name_length <= 0
    if name.length > max_name_length
      errors.add :name, :too_long, { count: max_name_length }
    end
  end

  def remove_private_dir
    ::FileUtils.rm_rf private_dir
  end
end
