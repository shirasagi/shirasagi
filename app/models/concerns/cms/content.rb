module Cms::Content
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Cms::TemplateVariable
  include SS::Liquidization
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::GroupPermission
  include Cms::CheckLinks
  include Fs::FilePreviewable
  include History::Addon::Trash
  include Cms::ContentLiquid

  attr_accessor :cur_node, :basename

  included do
    cattr_accessor(:default_released_type, instance_accessor: false)
    self.default_released_type = "fixed"

    define_model_callbacks :chorg

    seqid :id
    field :state, type: String, default: "public"
    field :name, type: String
    field :index_name, type: String
    field :filename, type: String
    field :depth, type: Integer
    field :order, type: Integer, default: 0
    field :released, type: DateTime
    field :released_type, type: String, default: ->{ self.class.default_released_type }
    field :first_released, type: DateTime
    field :imported, type: DateTime
    field :md5, type: String

    permit_params :state, :name, :index_name, :filename, :basename, :order, :released, :released_type, :route

    validates :state, presence: true
    validates :name, presence: true
    validates :filename, uniqueness: { scope: :site_id }, length: { maximum: 200 }
    validates :released, datetime: true
    after_validation :update_released, if: -> { public? }
    before_validation :set_filename
    before_validation :validate_filename
    after_validation :set_depth, if: ->{ filename.present? }

    validate :validate_name, if: ->{ name.present? }

    after_destroy :remove_private_dir
  end

  module ClassMethods
    def filename(name)
      all.where(filename: name.sub(/^\//, ""))
    end

    def node(node, target = nil)
      if target == 'descendant'
        node ? all.where(filename: /^#{::Regexp.escape(node.filename)}\//) : all
      else #current
        node ? all.where(filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1) : all.where(depth: 1)
      end
    end

    def and_public_selector(date)
      date = date ? date.dup : Time.zone.now
      conditions = []
      conditions << { state: "public", release_date: nil, close_date: nil }
      conditions << { state: "public", release_date: { "$lte" => date }, close_date: { "$gt" => date } }
      conditions << { state: "ready", release_date: { "$lte" => date }, close_date: { "$gt" => date } }
      conditions << { state: "public", release_date: nil, close_date: { "$gt" => date } }
      conditions << { state: "public", release_date: { "$lte" => date }, close_date: nil }
      conditions << { state: "ready", release_date: { "$lte" => date }, close_date: nil }
      { "$and" => [{ "$or" => conditions }] }
    end

    def and_public(date = nil)
      all.where(and_public_selector(date))
    end

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

      # condition_hash
      if parent_item
        ids = []
        if parent_item.respond_to?(:condition_hash)
          # list addon included
          condition_hash = parent_item.condition_hash(opts.slice(*Cms::Addon::List::Model::WELL_KONWN_CONDITION_HASH_OPTIONS))
          criteria = self.unscoped.where(condition_hash)
          if parent_item.respond_to?(:condition_forms) && parent_item.condition_forms.present?
            extra_conditions = parent_item.condition_forms.to_mongo_query
            if extra_conditions.length == 1
              criteria = criteria.where(extra_conditions.first)
            elsif extra_conditions.length > 1
              criteria = criteria.where("$and" => [{ "$or" => extra_conditions }])
            end
          end
          ids += criteria.distinct(:id)
        end
        return self.none if ids.blank?

        ids.uniq!
        criteria = all.in(id: ids)
        criteria = criteria.hint({ _id: 1 })

        # criteria.count does not use hint
        def criteria.count(options = {}, &block)
          options = options.symbolize_keys
          options[:hint] = { _id: 1 }
          begin
            super(options, &block)
          rescue Mongo::Error::OperationFailure => e
            Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join('\n  ')}")
            options.delete(:hint)
            super(options, &block)
          end
        end
      end

      # default criteria (no list addon included)
      criteria = self.all.site(site) if criteria.blank?

      # and_public
      criteria.and_public(date)
    end

    def private_root
      "#{SS::Application.private_root}/#{self.collection_name}"
    end
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
    "#{(@cur_site || site).path}/#{filename}"
  end

  def url
    "#{(@cur_site || site).url}#{filename}"
  end

  def full_url
    "#{(@cur_site || site).full_url}#{filename}"
  end

  def json_path
    "#{(@cur_site || site).path}/" + filename.sub(/(\/|\.html)?$/, ".json")
  end

  def json_url
    (@cur_site || site).url + filename.sub(/(\/|\.html)?$/, ".json")
  end

  def private_dir
    return if new_record?
    self.class.private_root + "/" + id.to_s.chars.join("/") + "/_"
  end

  def private_file(basename)
    return if new_record?
    "#{private_dir}/#{basename}"
  end

  def date
    released_type = self.released_type.presence || self.class.default_released_type
    Cms.cms_page_date(released_type, self[:released], updated, created, first_released)
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
    return self if name.blank?

    # be careful, Cms::Layout does not respond to route
    return self if respond_to?(:route) && name == route

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

  def file_previewable?(file, site:, user:, member:)
    return false unless public?
    return false unless public_node?
    return false if try(:for_member_enabled?) && member.blank?
    return false if !site || !site.is_a?(SS::Model::Site) || self.site_id != site.id
    true
  end

  def released_type_options
    %w(fixed same_as_updated same_as_created same_as_first_released).map do |v|
      [ I18n.t("cms.options.released_type.#{v}"), v ]
    end
  end

  def state_changeable?
    self.is_a?(Cms::Addon::Release)
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

  def update_released(now = nil)
    now ||= Time.zone.now
    self.first_released ||= now

    case released_type
    when "same_as_updated"
      if changed? && record_timestamps
        # #updated とは少なくともミリ秒での誤差があるので、厳密には違うが、だいたいあっている。
        self.released = now
      end
    when "same_as_created"
      if persisted?
        self.released = self.created
      else
        # #created とは少なくともミリ秒での誤差があるので、厳密には少し違うがだいたいあっている。
        # そして、次に更新する際にミリ秒レベルで同期されるのでよしとする。
        self.released = now
      end
    when "same_as_first_released"
      self.released = self.first_released
    else # nil or "fixed"
      self.released ||= now
    end
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
    backup.ref_class = self.class.to_s
    backup.data = attributes
    backup.data.delete(:lock_until)
    backup.data.delete(:lock_owner_id)
    backup.site = @cur_site || self.site
    backup.user = @cur_user
    backup.save
  end

  def validate_name
    max_name_length = (@cur_site || site).try(:max_name_length).to_i

    return if max_name_length <= 0
    if name.length > max_name_length
      errors.add :name, :too_long, count: max_name_length
    end
  end

  def remove_private_dir
    ::FileUtils.rm_rf private_dir
  end
end
