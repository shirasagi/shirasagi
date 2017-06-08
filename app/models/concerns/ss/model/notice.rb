module SS::Model::Notice
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include Sys::Addon::Body
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan

  NOTICE_SEVERITY_NORMAL = "normal".freeze
  NOTICE_SEVERITY_HIGH ="high".freeze
  NOTICE_SEVERITIES = [ NOTICE_SEVERITY_NORMAL, NOTICE_SEVERITY_HIGH ].freeze

  NOTICE_TARGET_LOGIN_VIEW = "login_view".freeze
  NOTICE_TARGET_CMS_ADMIN = "cms_admin".freeze
  NOTICE_TARGET_GROUP_WEAR = "gw_admin".freeze
  NOTICE_TARGET_WEB_MAIL = "webmail_admin".freeze
  NOTICE_TARGET_SYS_ADMIN = "sys_admin".freeze
  NOTICE_TARGETS = [
    NOTICE_TARGET_LOGIN_VIEW,
    NOTICE_TARGET_CMS_ADMIN,
    NOTICE_TARGET_GROUP_WEAR,
    NOTICE_TARGET_WEB_MAIL,
    NOTICE_TARGET_SYS_ADMIN
  ].freeze

  included do
    seqid :id
    field :state, type: String, default: "public"
    field :name, type: String
    field :released, type: DateTime
    field :notice_severity, type: String, default: NOTICE_SEVERITY_NORMAL
    field :notice_target, type: Array, default: []

    permit_params :state, :html, :name, :released, :notice_severity, notice_target:[]

    validates :state, presence: true
    validates :name, presence: true, length: { maximum: 80 }
    validates :released, datetime: true

    after_validation :set_released, if: -> { state == "public" }

    default_scope -> {
      order_by released: -1
    }

    scope :cms_admin_notice, -> {
      where(:notice_target.in => [NOTICE_TARGET_CMS_ADMIN])
    }

    scope :sys_admin_notice, -> {
      where(:notice_target.in => [NOTICE_TARGET_SYS_ADMIN])
    }

    scope :gw_admin_notice, -> {
      where(:notice_target.in => [NOTICE_TARGET_GROUP_WEAR])
    }

    scope :webmail_admin_notice, -> {
      where(:notice_target.in => [NOTICE_TARGET_WEB_MAIL])
    }

    scope :and_show_login, -> {
      where(:notice_target.in => [NOTICE_TARGET_LOGIN_VIEW])
    }

    scope :and_public, ->(date = Time.zone.now) {
      where("$and" => [
        { state: "public" },
        { "$or" => [ { :released.lte => date }, { :release_date.lte => date } ] },
        { "$or" => [ { close_date: nil }, { :close_date.gt => date } ] },
      ])
    }

    scope :and_user, ->(user){
      where(user_id: user.id)
    }
    scope :target_to, ->(user) {
      where("$or" => [
        { notice_target: NOTICE_TARGET_LOGIN_VIEW },
        { "$and" => [ { notice_target: NOTICE_TARGET_CMS_ADMIN }, { :group_ids.in => user.group_ids } ] }
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
      NOTICE_TARGETS.map { |v| [ I18n.t("cms.options.notice_target.#{v}"), v ] }
    end

    def disp_notice_target(target)
      I18n.t("cms.options.notice_target.#{target}")
    end

    def state_options
      [
        [I18n.t('ss.options.state.public'), 'public'],
        [I18n.t('ss.options.state.closed'), 'closed'],
      ]
    end

    def new_clone(attributes = {})
      attributes = self.attributes.merge(attributes).select{ |k| self.fields.keys.include?(k) }

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
      ids = SS::Extensions::Words.new
      files.each do |f|
        attributes = Hash[f.attributes]
        attributes.select!{ |k| f.fields.keys.include?(k) }

        file = SS::File.new(attributes)
        file.id = nil
        file.in_file = f.uploaded_file
        file.user_id = @cur_user.id if @cur_user

        file.save validate: false
        ids << file.id.mongoize

        html = self.html
        html.gsub!("=\"#{f.url}\"", "=\"#{file.url}\"")
        html.gsub!("=\"#{f.thumb_url}\"", "=\"#{file.thumb_url}\"")
        self.html = html
      end
      self.file_ids = ids
    end
  end

  private

  def set_released
    self.released ||= Time.zone.now
  end
end
