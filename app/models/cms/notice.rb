class Cms::Notice
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::Body
  include Cms::Addon::File
  include SS::Addon::Release
  include Cms::Addon::GroupPermission
  include Fs::FilePreviewable

  NOTICE_SEVERITY_NORMAL = "normal".freeze
  NOTICE_SEVERITY_HIGH ="high".freeze
  NOTICE_SEVERITIES = [ NOTICE_SEVERITY_NORMAL, NOTICE_SEVERITY_HIGH ].freeze

  NOTICE_TARGET_ALL = "all".freeze
  NOTICE_TARGET_SAME_GROUP = "same_group".freeze
  NOTICE_TARGETS = [ NOTICE_TARGET_ALL, NOTICE_TARGET_SAME_GROUP ].freeze

  seqid :id
  field :name, type: String
  field :notice_severity, type: String, default: NOTICE_SEVERITY_NORMAL
  field :notice_target, type: String, default: NOTICE_TARGET_ALL

  permit_params :name, :notice_severity, :notice_target

  validates :name, presence: true, length: { maximum: 80 }

  scope :target_to, ->(user) {
    where("$or" => [
      { notice_target: NOTICE_TARGET_ALL },
      { "$and" => [ { notice_target: NOTICE_TARGET_SAME_GROUP }, { :group_ids.in => user.group_ids } ] }
    ])
  }
  scope :search, ->(params = {}) {
    criteria = self.where({})
    return criteria if params.blank?

    criteria = criteria.search_text params[:name] if params[:name].present?
    criteria = criteria.keyword_in params[:keyword], :name, :html if params[:keyword].present?
    criteria
  }

  def notice_severity_options
    NOTICE_SEVERITIES.map { |v| [ I18n.t("cms.options.notice_severity.#{v}"), v ] }.to_a
  end

  def notice_target_options
    NOTICE_TARGETS.map { |v| [ I18n.t("cms.options.notice_target.#{v}"), v ] }.to_a
  end

  def new_clone(attributes = {})
    attributes = self.attributes.merge(attributes).select{ |k| self.fields.key?(k) }

    item = self.class.new(attributes)
    item.id = nil
    item.cur_site = @cur_site
    item.state = 'closed'
    # item.cur_node = @cur_node
    item.instance_variable_set(:@new_clone, true)
    item
  end

  def new_clone?
    @new_clone == true
  end

  def clone_files
    run_callbacks(:clone_files) do
      ids = {}
      files.each do |f|
        attributes = Hash[f.attributes]
        attributes.select!{ |k| f.fields.key?(k) }

        file = SS::File.new(attributes)
        file.id = nil
        file.in_file = f.uploaded_file
        file.user_id = @cur_user.id if @cur_user
        file.owner_item = self if file.respond_to?(:owner_item=)

        file.save validate: false
        ids[f.id] = file.id

        html = self.html
        html.gsub!("=\"#{f.url}\"", "=\"#{file.url}\"")
        html.gsub!("=\"#{f.thumb_url}\"", "=\"#{file.thumb_url}\"")
        self.html = html
      end
      self.file_ids = ids.values
      ids
    end
  end

  def file_previewable?(file, user:, member:)
    return false if !file_ids.include?(file.id)
    return false if user.blank?

    return true if state == "public" && notice_target == NOTICE_TARGET_ALL

    allowed?(:read, user, site: @cur_site || site)
  end
end
