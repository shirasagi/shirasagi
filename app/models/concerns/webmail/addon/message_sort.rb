module Webmail::Addon::MessageSort
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :webmail_message_sort, type: Hash, default: {}
  end

  def webmail_message_sort_hash(webmail_mode, account, mailbox, sort, order)
    return @sort_hash if @sort_hash

    order = (order == "1") ? 1 : -1
    if sort.present? && %w(from to subject internal_date size).include?(sort)
      @sort_hash = { sort => order }
    else
      # @sort_hash = webmail_message_sort.dig(folder.site_id.to_s, folder.folder_path.tr(".", "_"))
      @sort_hash = webmail_message_sort.dig(webmail_mode, account, mailbox.to_s)
      @sort_hash ||= { "internal_date" => -1 }
    end

    k1 = webmail_mode
    k2 = account
    k3 = mailbox.to_s
    self.webmail_message_sort[k1] ||= {}
    self.webmail_message_sort[k1][k2] ||= {}
    if self.webmail_message_sort[k1][k2][k3] != @sort_hash
      self.webmail_message_sort[k1][k2][k3] = @sort_hash
      save
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
    if sort_hash[name] == -1
      '<i class="material-icons md-18">&#xE313;</i>'
    elsif sort_hash[name] == 1
      '<i class="material-icons md-18">&#xE316;</i>'
    else
      '<i class="material-icons md-18" style="visibility: hidden;">&#xE313;</i>'
    end
  end
end
