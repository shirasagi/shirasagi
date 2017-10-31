module Webmail::Imap
  class Mail
    include Webmail::ImapAccessor

    def initialize(imap)
      @imap = imap
      @mailbox = 'INBOX'
      @search = %w(UNDELETED)
      @sort = %w(REVERSE ARRIVAL)
      @limit = 50
      @page = 1
    end

    def mailbox(mailbox)
      @mailbox = mailbox
      self
    end

    def page(page)
      page = page.presence
      @page = page ? page.to_i : 1
      self
    end

    def per(per)
      @limit = per
      self
    end

    def offset
      (@page - 1) * @limit
    end

    def search(params)
      @search = %w(UNDELETED)
      return self if params.blank?

      [:from, :to, :subject, :text].each do |key|
        next if params[key].blank?
        @search << key.to_s.upcase
        @search << params[key].dup.force_encoding('ASCII-8BIT')
      end

      [:since, :before, :sentsince, :sentbefore].each do |key|
        next if params[key].blank?
        @search << key.to_s.upcase
        @search << Date.parse(params[key]).strftime('%-d-%b-%Y')
      end

      [:flagged, :unflagged, :seen, :unseen].each do |key|
        next if params[key].blank?
        @search << key.to_s.upcase
      end

      self
    end

    def condition
      { mailbox: @mailbox, sort: @sort, page: @page, limit: @limit, search: @search }
    end

    def uids
      imap.conn.uid_sort(@sort, @search, 'UTF-8')
    end

    def all
      uids = imap.conn.uid_sort(@sort, @search, 'UTF-8')
      size = uids.size
      uids = uids.slice(offset, @limit) || []

      items = {}
      uids.each { |uid| items[uid] = nil }

      uids = cache_all(uids, items) if uids.present? && SS.config.webmail.cache_mails
      uids = imap_all(uids, items) if uids.present?

      Kaminari.paginate_array(items.values, total_count: size).page(@page).per(@limit)
    end

    def find(uid, *division)
      uid = uid.to_i

      attr = %w(FLAGS INTERNALDATE RFC822.SIZE RFC822.HEADER) # FAST: FLAGS INTERNALDATE RFC822.SIZE
      attr += %w(BODYSTRUCTURE) if division.include?(:body)
      attr << 'RFC822' if division.include?(:rfc822)

      resp = imap.conn.uid_fetch(uid, attr)
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless resp

      item = Webmail::Mail.new
      item.imap = imap
      item.parse(resp[0])
      item.fetch_body if division.include?(:body)
      item
    end

    def find_part(uid, section)
      uid = uid.to_i

      resp = imap.conn.uid_fetch(uid, ['BODYSTRUCTURE', "BODY[#{section}]"])
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless resp

      item = Webmail::Mail.new
      item.imap = imap
      item.body_structure = resp[0].attr['BODYSTRUCTURE']

      part = item.all_parts[section]
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless part

      Webmail::MailPart.new(part, section, resp[0].attr["BODY[#{section}]"])
    end

    def find_and_store(uid, *division)
      uid = uid.to_i

      attr = %w(FLAGS INTERNALDATE RFC822.SIZE RFC822.HEADER) # FAST: FLAGS INTERNALDATE RFC822.SIZE
      item = Webmail::Mail.where(mailbox_scope.merge(uid: uid)).first
      item ||= Webmail::Mail.new(mailbox_scope)
      item.parse_rfc822_body

      if item.rfc822
        # use cache
      else
        attr << 'RFC822' if division.include?(:body) || division.include?(:rfc822)
      end

      resp = imap.conn.uid_fetch(uid, attr)
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless resp

      item.imap = imap
      item.parse(resp[0])
      item.save
      item.save_rfc822 if attr.include?('RFC822')
      item
    end

    def find_part_and_store(uid, section)
      uid = uid.to_i
      section = section.to_i

      attr = %w(FLAGS INTERNALDATE RFC822.SIZE RFC822.HEADER) # FAST: FLAGS INTERNALDATE RFC822.SIZE
      item = Webmail::Mail.where(mailbox_scope.merge(uid: uid)).first
      item ||= Webmail::Mail.new(mailbox_scope)
      item.parse_rfc822_body

      if item.attachments.present?
        # use cache
      else
        attr << 'RFC822'
      end

      resp = imap.conn.uid_fetch(uid, attr)
      raise Mongoid::Errors::DocumentNotFound.new(Webmail::Imap, uid: uid) unless resp
      item.imap = imap
      item.parse(resp[0])
      item.save
      item.save_rfc822 if attr.include?('RFC822')

      item.attachments.select { |attachment| attachment.section == section }.first
    end

    private

    def mailbox_scope
      imap.account_scope.merge(mailbox: @mailbox)
    end

    def cache_all(uids, ref_items)
      items = Webmail::Mail.where(mailbox_scope).in(uid: uids)
      item_uids = items.map(&:uid)
      flags = []

      if items.present?
        resp = imap.conn.uid_fetch(item_uids, ['FLAGS']) || []
        resp.each do |data|
          flags[data.attr['UID']] = data.attr['FLAGS'] || []
        end
      end

      items.each do |item|
        next if ref_items[item.uid]
        item.flags = flags[item.uid]
        ref_items[item.uid] = item
      end

      uids - item_uids
    end

    def imap_all(uids, ref_items)
      resp = imap.conn.uid_fetch(uids, %w(FLAGS INTERNALDATE RFC822.SIZE RFC822.HEADER)) || []
      resp.each do |data|
        uid = data.attr['UID']
        uids.delete(uid)

        item = Webmail::Mail.new(mailbox_scope)
        ref_items[uid] = item

        begin
          item.parse(data)
          item.save if SS.config.webmail.cache_mails
        rescue => e
          raise e if Rails.env.development?
          item.subject = "[Error] #{e}"
        end
      end

      uids
    end
  end
end
