module Gws::Model
  module Memo::Message
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      store_in collection: "gws_memo_messages"

      attr_accessor :signature, :attachments, :field, :cur_site, :cur_user, :in_path, :in_request_mdn

      field :subject, type: String
      field :text, type: String, default: ''
      field :html, type: String
      field :format, type: String
      field :size, type: Integer, default: 0
      field :seen, type: Hash, default: {}
      field :star, type: Hash, default: {}
      field :filtered, type: Hash, default: {}
      field :state, type: String, default: 'public'
      field :path, type: Hash, default: {}
      field :send_date, type: DateTime

      embeds_ids :to_members, class_name: "Gws::User"
      embeds_ids :cc_members, class_name: "Gws::User"
      embeds_ids :bcc_members, class_name: "Gws::User"
      embeds_ids :request_mdn, class_name: "Gws::User"

      permit_params :subject, :text, :html, :format, :in_path, :in_request_mdn
      permit_params to_member_ids: [], cc_member_ids: [], bcc_member_ids: []

      default_scope -> { order_by(send_date: -1, updated: -1) }

      after_initialize :set_default_reminder_date, if: :new_record?

      before_validation :set_member_ids
      before_validation :set_request_mdn
      before_validation :set_send_date
      before_validation :set_path
      before_validation :set_size

      validate :validate_attached_file_size

      scope :search, ->(params) {
        criteria = where({})
        return criteria if params.blank?

        if params[:subject].present?
          criteria = criteria.keyword_in params[:subject], :subject
        end

        params.values_at(:text, :html).reject(&:blank?).each do |value|
          criteria = criteria.keyword_in value, :text, :html
        end

        criteria
      }
      scope :and_public, ->() { where(state: "public") }
      scope :and_closed, ->() { where(state: "closed") }
      scope :folder, ->(folder, user) {
        if folder.sent_box?
          user(user).and_public
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
      self.size = self.files.pluck(:size).inject(:+)
    end

    def set_member_ids
      self.member_ids = (to_member_ids + cc_member_ids + bcc_member_ids).uniq
    end

    def set_request_mdn
      return if in_request_mdn != "1"
      return if send_date.present?
      self.request_mdn_ids = self.member_ids - [@cur_user.id]
    end

    def set_send_date
      now = Time.zone.now
      self.send_date ||= now if state == "public"
      #self.seen[cur_user.id] ||= now if cur_user
    end

    public

    def display_subject
      subject.presence || 'No title'
    end

    def display_send_date
      send_date ? send_date.strftime('%Y/%m/%d %H:%M') : I18n.t('gws/memo/folder.inbox_draft')
    end

    def display_to
      to_members.map(&:long_name)
    end

    def display_cc
      cc_members.map(&:long_name)
    end

    def display_bcc
      bcc_members.map(&:long_name)
    end

    def attachments?
      files.present?
    end

    def unseen?(user = nil)
      return false if user.nil?
      seen.exclude?(user.id.to_s)
    end

    def star?(user = :nil)
      return false if user == :nil
      star.include?(user.id.to_s)
    end

    def display_size
      result = 1024

      if self.size && (self.size > result)
        result = self.size
      end

      ActiveSupport::NumberHelper.number_to_human_size(result, precision: 0)
    end

    def format_options
      %w(text html).map { |c| [c.upcase, c] }
    end

    def signature_options
      Gws::Memo::Signature.site(cur_site).allow(:read, cur_user, site: cur_site).map do |c|
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
      self.state == "closed"
    end

    def public?
      self.state == "public"
    end

    def apply_filters(user)
      matched_filter = Gws::Memo::Filter.site(site).user(user).enabled.detect{ |f| f.match?(self) }
      self.move(user, matched_filter.path) if matched_filter
      self.filtered[user.id.to_s] = Time.zone.now
      self
    end

    def new_memo
      if sign = Gws::Memo::Signature.default_sign(@cur_user)
        self.text = "\n\n#{sign}"
        self.html = "<p></p>" + h(sign.to_s).gsub(/\r\n|\n/, '<br />')
      end
    end

    def html?
      format == 'html'
    end

    def validate_attached_file_size
      return if site.memo_filesize_limit.blank?
      return if site.memo_filesize_limit <= 0

      limit = site.memo_filesize_limit * 1024 * 1024
      size = files.compact.map(&:size).sum

      if size > limit
        errors.add(:base, :file_size_limit, size: number_to_human_size(size), limit: number_to_human_size(limit))
      end
    end

    def reminder_date
      return if site.memo_reminder == 0
      result = Time.zone.now.beginning_of_day + (site.memo_reminder - 1).day
      result.end_of_day
    end

    def in_reminder_date
      if @in_reminder_date
        date = Time.zone.parse(@in_reminder_date) rescue nil
      end
      date ||= reminder ? reminder.date : reminder_date
      date
    end

    def set_default_reminder_date
      return unless @cur_site
      if @in_reminder_date.blank? && @cur_site.memo_reminder != 0
        @in_reminder_date = (Time.zone.now.beginning_of_day + (@cur_site.memo_reminder - 1).day).
            end_of_day.strftime("%Y/%m/%d %H:%M") unless @cur_site.memo_reminder == 0
      end
      @in_reminder_state = (@cur_site.memo_reminder == 0)
    end

    def h(str)
      ERB::Util.h(str)
    end

    module ClassMethods
      def unseens(user)
        self.member(user).unseen(user).and_public
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
