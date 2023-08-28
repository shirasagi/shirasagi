module Webmail::MessageSort
  extend ActiveSupport::Concern

  included do
    field :webmail_message_sort, type: Hash, default: {}
  end

  def webmail_message_sort_hash(webmail_mode, account, mailbox, sort, order)
    return @sort_hash if @sort_hash

    mailbox = mailbox.to_s.tr(".", "_")
    order = (order == "1") ? 1 : -1
    if sort.present? && %w(from to subject internal_date size).include?(sort)
      @sort_hash = { sort => order }
    else
      # @sort_hash = webmail_message_sort.dig(folder.site_id.to_s, folder.folder_path.tr(".", "_"))
      @sort_hash = webmail_message_sort.dig(webmail_mode, account, mailbox)
      @sort_hash ||= { "internal_date" => -1 }
    end

    k1 = webmail_mode
    k2 = account
    k3 = mailbox
    self.webmail_message_sort[k1] ||= {}
    self.webmail_message_sort[k1][k2] ||= {}
    if self.webmail_message_sort[k1][k2][k3] != @sort_hash
      self.webmail_message_sort[k1][k2][k3] = @sort_hash

      without_record_timestamps do
        save
      end
    end

    @sort_hash
  end

  def webmail_message_sort_query(sort_hash, name)
    if sort_hash[name] == -1
      { "sort" => name, "order" => 1 }
    else
      { "sort" => name, "order" => -1 }
    end
  end

  def webmail_message_sort_icon(sort_hash, name)
    case sort_hash[name]
    when -1
      '<i class="material-icons md-18">keyboard_arrow_down</i>'
    when 1
      '<i class="material-icons md-18">keyboard_arrow_up</i>'
    else
      '<i class="material-icons md-18" style="visibility: hidden;">keyboard_arrow_down</i>'
    end
  end
end
