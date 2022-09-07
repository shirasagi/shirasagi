module Gws::Model
  module Memo::Message
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      store_in collection: "gws_memo_messages"

      attr_accessor :signature, :attachments, :field, :cur_site, :cur_user, :in_path, :in_request_mdn
      attr_accessor :in_to_members, :in_cc_members, :in_bcc_members

      field :type, type: String
      field :subject, type: String
      field :text, type: String, default: ''
      field :html, type: String, default: ''
      field :format, type: String
      field :size, type: Integer, default: 0
      field :star, type: Hash, default: {}
      field :filtered, type: Hash, default: {}
      field :deleted, type: Hash, default: {}
      field :state, type: String, default: 'public'
      field :send_date, type: DateTime
      field :user_settings, type: Array, default: []

      field :to_member_name, type: String, default: ''
      field :from_member_name, type: String, default: ''

      embeds_ids :to_members, class_name: "Gws::User"
      embeds_ids :to_webmail_address_groups, class_name: "Webmail::AddressGroup"
      embeds_ids :to_shared_address_groups, class_name: "Gws::SharedAddress::Group"

      embeds_ids :cc_members, class_name: "Gws::User"
      embeds_ids :cc_webmail_address_groups, class_name: "Webmail::AddressGroup"
      embeds_ids :cc_shared_address_groups, class_name: "Gws::SharedAddress::Group"

      embeds_ids :bcc_members, class_name: "Gws::User"
      embeds_ids :bcc_webmail_address_groups, class_name: "Webmail::AddressGroup"
      embeds_ids :bcc_shared_address_groups, class_name: "Gws::SharedAddress::Group"

      embeds_ids :request_mdn, class_name: "Gws::User"

      permit_params :subject, :text, :html, :format, :in_path, :in_request_mdn
      # permit_params to_member_ids: [], cc_member_ids: [], bcc_member_ids: []
      permit_params in_to_members: [], in_cc_members: [], in_bcc_members: []

      default_scope -> { order_by(send_date: -1, updated: -1) }

      #after_initialize :set_default_reminder_date, if: :new_record?

      before_validation :set_type
      before_validation :set_member_ids
      before_validation :set_request_mdn
      before_validation :set_send_date
      before_validation :set_path
      before_validation :set_size
      before_validation :set_member_name

      validates :subject, presence: true, length: { maximum: 200 }

      scope :and_public, -> { where(state: "public") }
      scope :and_closed, -> { self.and('$or' => [ { :state.ne => "public" }, { :state.exists => false } ]) }
      scope :folder, ->(folder, user) {
        if folder.sent_box?
          user(user).where(:"deleted.sent".exists => false).and_public # rubocop:disable Style/QuotedSymbols
        elsif folder.draft_box?
          user(user).and_closed
        else
          where(user_settings: { "$elemMatch" => { 'user_id' => user.id, 'path' => folder.folder_path } }).and_public
        end
      }
      scope :unseen, ->(user, opts = {}) {
        conditions = { 'user_id' => user.id, 'seen_at' => { "$exists" => false } }
        conditions['path'] = opts[:path] if opts[:path].present?
        where(user_settings: { "$elemMatch" => conditions })
      }
      scope :unfiltered, ->(user) {
        where(:"filtered.#{user.id}".exists => false)
      }
    end

    private

    def set_path
      self.user_settings = member_ids.collect do |member_id|
        user_setting_was = (user_settings_was.presence || []).find{ |setting| setting['user_id'] == member_id }
        path = in_path.try(:[], member_id.to_s).presence || user_setting_was.try(:[], 'path').presence || 'INBOX'
        seen_at = user_settings.find { |setting| setting['user_id'] == member_id }.try(:[], 'seen_at')
        user_setting = { 'user_id' => member_id, 'path' => path }
        user_setting['seen_at'] = seen_at.in_time_zone.utc if seen_at.present?
        user_setting
      end
    end

    def set_size
      #self.size = subject.bytesize
      #self.size += text.bytesize if text.present?
      #self.size += html.bytesize if html.present?
      self.size = 1024
      self.size += files.pluck(:size).sum if files.present?
    end

    def set_member_name
      self.from_member_name = @cur_user.long_name if @cur_user && from_member_name.blank?
      self.to_member_name = display_to.join("; ")
    end

    def in_recipients?
      return true if Array(in_to_members).flatten.compact.uniq.select(&:present?).present?
      return true if Array(in_cc_members).flatten.compact.uniq.select(&:present?).present?
      return true if Array(in_bcc_members).flatten.compact.uniq.select(&:present?).present?

      false
    end

    def extract_members(in_members)
      users = []
      webmail_address_groups = []
      shared_address_groups = []

      Array(in_members).flatten.compact.uniq.select(&:present?).each do |member_id|
        if member_id.to_s.start_with?('webmail_group:')
          group_id = member_id[14..-1]
          webmail_address_groups << Webmail::AddressGroup.user(@cur_user).find(group_id) rescue nil
        elsif member_id.to_s.start_with?('shared_group:')
          group_id = member_id[13..-1]
          shared_address_groups << Gws::SharedAddress::Group.site(@cur_site).find(group_id) rescue nil
        else
          users << Gws::User.find(member_id) rescue nil
        end
      end

      [ users.compact, webmail_address_groups.compact, shared_address_groups.compact ]
    end

    def extract_to_members
      members, webmail_address_groups, shared_address_groups = extract_members(in_to_members)
      self.to_member_ids = members.map(&:id)
      self.to_webmail_address_group_ids = webmail_address_groups.map(&:id)
      self.to_shared_address_group_ids = shared_address_groups.map(&:id)
    end

    def extract_cc_members
      members, webmail_address_groups, shared_address_groups = extract_members(in_cc_members)
      self.cc_member_ids = members.map(&:id)
      self.cc_webmail_address_group_ids = webmail_address_groups.map(&:id)
      self.cc_shared_address_group_ids = shared_address_groups.map(&:id)
    end

    def extract_bcc_members
      members, webmail_address_groups, shared_address_groups = extract_members(in_bcc_members)
      self.bcc_member_ids = members.map(&:id)
      self.bcc_webmail_address_group_ids = webmail_address_groups.map(&:id)
      self.bcc_shared_address_group_ids = shared_address_groups.map(&:id)
    end

    def extract_overall_members
      ids = []
      ids += Array(to_member_ids)
      ids += Array(cc_member_ids)
      ids += Array(bcc_member_ids)

      group_ids = Array(to_webmail_address_group_ids) + Array(cc_webmail_address_group_ids) + Array(bcc_webmail_address_group_ids)
      ids += Webmail::Address.user(@cur_user).
        in(address_group_id: group_ids).pluck(:member_id)

      group_ids = Array(to_shared_address_group_ids) + Array(cc_shared_address_group_ids) + Array(bcc_shared_address_group_ids)
      ids += Gws::SharedAddress::Address.site(@cur_site).readable(@cur_user, site: @cur_site).
        in(address_group_id: group_ids).pluck(:member_id)

      self.member_ids = Gws::User.in(id: ids.compact.uniq).pluck(:id)
    end

    def set_type
      self.type ||= self.class.model_name.name
    end

    def set_member_ids
      # self.member_ids = (to_member_ids + cc_member_ids + bcc_member_ids).uniq
      if in_to_members.present? || in_cc_members.present? || in_bcc_members.present?
        extract_to_members
        extract_cc_members
        extract_bcc_members
        extract_overall_members
      end

      self.member_ids = member_ids - deleted.keys.map(&:to_i)
    end

    def set_request_mdn
      return if in_request_mdn != "1"
      return if send_date.present?
      return unless @cur_user

      self.request_mdn_ids = self.member_ids - [@cur_user.id]
    end

    def set_send_date
      now = Time.zone.now
      self.send_date ||= now if public?
      #self.seen[cur_user.id] ||= now if cur_user
    end

    public

    def readable?(user, opts = {})
      return false if self.site_id != opts[:site].id
      return true if member?(user)

      if self.respond_to?(:user_id) && self.user_id == user.id
        if deleted["sent"]
          return false
        else
          return true
        end
      end

      false
    end

    def editable?(user, site)
      return false if self.site_id != site.id

      (self.user_id == user.id && draft?)
    end

    def display_subject
      subject.presence || I18n.t('gws/memo.no_subjects')
    end

    def display_send_date
      send_date ? I18n.l(send_date, format: :picker) : I18n.t('gws/memo/folder.inbox_draft')
    end

    def to_members?
      to_members.present? || to_webmail_address_groups.present? || to_shared_address_groups.present?
    end

    def cc_members?
      cc_members.present? || cc_webmail_address_groups.present? || cc_shared_address_groups.present?
    end

    def bcc_members?
      bcc_members.present? || bcc_webmail_address_groups.present? || bcc_shared_address_groups.present?
    end

    def display_to
      sorted_to_members.map(&:long_name) + to_webmail_address_groups.pluck(:name) + to_shared_address_groups.pluck(:name)
    end

    def display_cc
      sorted_cc_members.map(&:long_name) + cc_webmail_address_groups.pluck(:name) + cc_shared_address_groups.pluck(:name)
    end

    def display_bcc
      sorted_bcc_members.map(&:long_name) + bcc_webmail_address_groups.pluck(:name) + bcc_shared_address_groups.pluck(:name)
    end

    def attachments?
      return false if file_ids.blank?

      files.present?
    end

    def unseen?(user)
      return false unless user

      user_settings.find { |setting| setting['user_id'] == user.id && setting['seen_at'].present? }.blank?
    end

    def seen_at(user)
      return if user.blank?

      found = user_settings.find { |setting| setting['user_id'] == user.id && setting['seen_at'].present? }
      return if found.blank?

      found['seen_at'].try { |time| time.in_time_zone }
    end

    def path(user)
      return if user.blank?

      found = user_settings.find { |setting| setting['user_id'] == user.id }
      return if found.blank?

      found['path']
    end

    def star?(user)
      return false unless user

      star.include?(user.id.to_s)
    end

    def destroy_from_folder(user, folder, opts = {})
      unsend = opts[:unsend]

      if folder.draft_box?
        destroy
      elsif folder.sent_box? && unsend == "1"
        destroy
      elsif folder.sent_box?
        destroy_from_sent
      else
        destroy_from_member(user)
      end
    end

    def destroy_from_member(user)
      self.member_ids = member_ids - [user.id]
      self.deleted[user.id.to_s] = Time.zone.now.utc

      if member_ids.blank? && deleted["sent"]
        destroy
      else
        update
      end
    end

    def destroy_from_sent
      self.deleted["sent"] = Time.zone.now.utc

      if member_ids.blank? && deleted["sent"]
        destroy
      else
        update
      end
    end

    def display_size
      ActiveSupport::NumberHelper.number_to_human_size((size.to_i > 1024 ? size.to_i : 1024))
    end

    def format_options
      %w(text html).map { |c| [c.upcase, c] }
    end

    def signature_options
      Gws::Memo::Signature.site(cur_site).user(cur_user).map do |c|
        [c.name, c.text]
      end
    end

    def template_options
      @template_options ||= Gws::Memo::Template.site(cur_site).map do |c|
        [c.name, c.text]
      end
    end

    def set_seen(user)
      self.user_settings = user_settings.collect do |setting|
        setting['seen_at'] = Time.zone.now.utc if user.id.to_s == setting['user_id'].to_s
        setting
      end
      self
    end

    def unset_seen(user)
      self.user_settings = user_settings.collect do |setting|
        setting['seen_at'] = nil if user.id.to_s == setting['user_id'].to_s
        setting
      end
      self
    end

    def set_star(user)
      self.star[user.id.to_s] = Time.zone.now.utc
      self
    end

    def unset_star(user)
      self.star.delete(user.id.to_s)
      self
    end

    # def toggle_star(user)
    #   star?(user) ? unset_star(user) : set_star(user)
    # end

    def move(user, path)
      self.in_path = { user.id.to_s => path }
      self
    end

    def draft?
      !public?
    end

    def public?
      self.state == "public"
    end

    def new_memo(opts = {})
      to = opts[:to]
      ref = opts[:ref]

      if sign = Gws::Memo::Signature.site(@cur_site).default_sign(@cur_user)
        self.text = "\n\n#{sign}"
        self.html = "<p></p>" + h(sign.to_s).gsub(/\r\n|\n/, '<br />')
      end

      if to.present?
        self.to_member_ids = to.is_a?(Array) ? to : [to]
      end

      if ref
        self.to_member_ids = ref.to_member_ids
        self.to_shared_address_group_ids = ref.to_shared_address_groups.readable(@cur_user, site: @cur_site).pluck(:id)
        self.cc_member_ids = ref.cc_member_ids
        self.cc_shared_address_group_ids = ref.cc_shared_address_groups.readable(@cur_user, site: @cur_site).pluck(:id)

        self.subject = ref.subject
        self.format = ref.format
        self.text = ref.text
        self.html = ref.html

        self.priority = ref.priority
      end
    end

    def html?
      format == 'html'
    end

    #def reminder_date
    #  return if site.memo_reminder == 0
    #  result = Time.zone.now.beginning_of_day + (site.memo_reminder - 1).day
    #  result.end_of_day
    #end

    #def in_reminder_date
    #  if @in_reminder_date
    #    date = Time.zone.parse(@in_reminder_date) rescue nil
    #  end
    #  date ||= reminder ? reminder.date : reminder_date
    #  date
    #end

    #def set_default_reminder_date
    #  return unless @cur_site
    #  if @in_reminder_date.blank? && @cur_site.memo_reminder != 0
    #    @in_reminder_date = (Time.zone.now.beginning_of_day + (@cur_site.memo_reminder - 1).day).
    #        end_of_day.strftime("%Y/%m/%d %H:%M")
    #  end
    #  @in_reminder_state = (@cur_site.memo_reminder == 0)
    #end

    def h(str)
      ERB::Util.h(str)
    end

    def list_message?
      self[:list_id].present?
    end

    def to_list_message
      Gws::Memo::ListMessage.find(self.id)
    end

    def write_as_eml(user, io, site: nil)
      Gws::Memo::Message::Eml.write(user, self, io, site: site)
    end

    module ClassMethods
      def create_from_eml(user, path, io, site:)
        message = Gws::Memo::Message::Eml.read(user, io, site: site)
        # message.user_settings = [{ "user_id" => user.id, "path" => path }]
        message.move(user, path)
        message.save
        message
      end

      def search(params)
        all.search_keyword(params).
          search_from_member_name(params).
          search_to_member_name(params).
          search_subject(params).
          search_text_or_html(params).
          search_date(params).
          search_state(params).
          search_unseen(params).
          search_flagged(params).
          search_priorities(params)
      end

      def search_keyword(params = {})
        return all if params.blank? || params[:keyword].blank?

        all.keyword_in(params[:keyword], :subject, :text, :html)
      end

      def search_from_member_name(params = {})
        return all if params.blank? || params[:from_member_name].blank?

        all.keyword_in params[:from_member_name], :from_member_name
      end

      def search_to_member_name(params = {})
        return all if params.blank? || params[:to_member_name].blank?

        all.keyword_in params[:to_member_name], :to_member_name
      end

      def search_subject(params = {})
        return all if params.blank? || params[:subject].blank?

        all.keyword_in params[:subject], :subject
      end

      def search_text_or_html(params = {})
        return all if params.blank? || (params[:text].blank? && params[:html].blank?)

        criteria = all
        params.values_at(:text, :html).reject(&:blank?).each do |value|
          criteria = criteria.keyword_in value, :text, :html
        end
        criteria
      end

      def search_state(params = {})
        return all if params.blank? || params[:state].blank?

        all.where(state: params[:state])
      end

      def search_date(params)
        return all if params.blank?

        cond = []
        cond << [ send_date: { "$gte" => params[:since] } ] if params[:since].present?
        cond << [ send_date: { "$lte" => params[:before] } ] if params[:before].present?
        return all if cond.blank?

        all.and(cond)
      end

      def search_unseen(params = {})
        return all if params.blank? || params[:unseen].blank?

        user_id = params[:unseen]
        all.and(user_settings: { "$elemMatch" => { 'user_id' => user_id.to_i, 'seen_at' => { "$exists" => false } } })
      end

      def search_flagged(params = {})
        return all if params.blank? || params[:flagged].blank?

        user_id = params[:flagged]
        all.and("star.#{user_id}" => { "$exists" => true })
      end

      def search_priorities(params = {})
        return all if params.blank?

        priorities = params[:priorities].to_a.select(&:present?)
        return all if priorities.blank?

        all.and([priority: { "$in" => priorities }])
      end

      def unseens(user, site)
        self.site(site).unseen(user).and_public
        #self.where('$and' => [
        #  { "to.#{user.id}".to_sym.exists => true },
        #  { "seen.#{user.id}".to_sym.exists => false },
        #  { "$where" => "function(){
        #    var self = this;
        #    var result = false;
        #    Object.keys(this.from).forEach(function(key){
        #      if (self.from[key] !== 'INBOX.Draft') { result = true; }
        #    })
        #    return result;
        #  }"}]
        #)
      end
    end
  end
end
