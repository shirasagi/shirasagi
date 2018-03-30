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
      field :seen, type: Hash, default: {}
      field :star, type: Hash, default: {}
      field :filtered, type: Hash, default: {}
      field :deleted, type: Hash, default: {}
      field :state, type: String, default: 'public'
      field :path, type: Hash, default: {}
      field :send_date, type: DateTime
      field :import_info, type: Hash, default: nil

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

      validates :subject, presence: true

      # scope :search, ->(params) {
      #   criteria = where({})
      #   return criteria if params.blank?
      #
      #   if params[:subject].present?
      #     criteria = criteria.keyword_in params[:subject], :subject
      #   end
      #
      #   params.values_at(:text, :html).reject(&:blank?).each do |value|
      #     criteria = criteria.keyword_in value, :text, :html
      #   end
      #
      #   criteria
      # }
      scope :and_public, -> { where(state: "public") }
      scope :and_closed, -> { self.and('$or' => [ { :state.ne => "public" }, { :state.exists => false } ]) }
      scope :folder, ->(folder, user) {
        if folder.sent_box?
          user(user).where(:"deleted.sent".exists => false).and_public
        elsif folder.draft_box?
          user(user).and_closed
        else
          where("path.#{user.id}" => folder.folder_path).and_public
        end
      }
      scope :unseen, ->(user) {
        where("seen.#{user.id}" => { '$exists' => false })
      }
      scope :unfiltered, ->(user) {
        where(:"filtered.#{user.id}".exists => false)
      }
    end

    private

    def set_path
      self.path = {}

      member_ids.each do |member_id|
        if path_was && path_was[member_id.to_s]
          self.path[member_id.to_s] = path_was[member_id.to_s]
        else
          self.path[member_id.to_s] = "INBOX"
        end
      end

      if in_path.present?
        in_path.each do |member_id, path|
          self.path[member_id.to_s] = path
        end
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

    def readable?(user, site)
      return false if self.site_id != site.id
      return true if member?(user)

      if self.user_id == user.id
        if deleted["sent"]
          return false
        else
          return true
        end
      end

      return false
    end

    def editable?(user, site)
      return false if self.site_id != site.id
      (self.user_id == user.id && draft?)
    end

    def display_subject
      subject.presence || I18n.t('gws/memo.no_subjects')
    end

    def display_send_date
      send_date ? send_date.strftime('%Y/%m/%d %H:%M') : I18n.t('gws/memo/folder.inbox_draft')
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
      files.present?
    end

    def unseen?(user)
      return false unless user
      seen.exclude?(user.id.to_s)
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
      self.deleted[user.id.to_s] = Time.zone.now

      if member_ids.blank? && deleted["sent"]
        destroy
      else
        update
      end
    end

    def destroy_from_sent
      self.deleted["sent"] = Time.zone.now

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
      self.seen[user.id.to_s] = Time.zone.now
      self
    end

    def unset_seen(user)
      self.seen.delete(user.id.to_s)
      self
    end

    def set_star(user)
      self.star[user.id.to_s] = Time.zone.now
      self
    end

    def unset_star(user)
      self.star.delete(user.id.to_s)
      self
    end

    def toggle_star(user)
      star?(user) ? unset_star(user) : set_star(user)
    end

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

    def new_memo(ref = nil)
      if sign = Gws::Memo::Signature.site(@cur_site).default_sign(@cur_user)
        self.text = "\n\n#{sign}"
        self.html = "<p></p>" + h(sign.to_s).gsub(/\r\n|\n/, '<br />')
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

    module ClassMethods
      def search(params)
        all.search_keyword(params).search_subject(params).search_text_or_html(params).search_state(params).search_unseen(params)
      end

      def search_keyword(params = {})
        return all if params.blank? || params[:keyword].blank?
        all.keyword_in(params[:keyword], :subject, :text, :html)
      end

      def search_subject(params = {})
        return all if params.blank? || params[:subject].blank?
        all.keyword_in params[:subject], :subject
      end

      def search_unseen(params = {})
        return all if params.blank? || params[:unseen].blank?
        user_id = params[:unseen]
        where("seen.#{user_id}" => { '$exists' => false })
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

      def unseens(user, site)
        self.member(user).site(site).unseen(user).and_public
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
