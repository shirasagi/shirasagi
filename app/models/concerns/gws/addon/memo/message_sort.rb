module Gws::Addon::Memo::MessageSort
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :gws_memo_message_sort, type: Hash, default: {}
  end

  def memo_message_sort_hash(folder, sort, order)
    return @sort_hash if @sort_hash

    order = (order == "1") ? 1 : -1
    if sort.present? && %w(from_member_name to_member_name subject priority send_date size).include?(sort)
      @sort_hash = { sort => order, "updated" => -1 }
    else
      @sort_hash = gws_memo_message_sort.dig(folder.site_id.to_s, folder.folder_path.tr(".", "_"))
      @sort_hash ||= { "send_date" => -1, "updated" => -1 }
    end

    k1 = folder.site_id.to_s
    k2 = folder.folder_path.tr(".", "_")
    self.gws_memo_message_sort[k1] ||= {}
    if self.gws_memo_message_sort[k1][k2] != @sort_hash
      self.gws_memo_message_sort[k1][k2] = @sort_hash
      save
    end

    @sort_hash
  end

  def memo_message_sort_query(sort_hash, name)
    if sort_hash[name] == -1
      { "sort" => name, "order" => 1 }
    else
      { "sort" => name, "order" => -1 }
    end
  end

  def memo_message_sort_icon(sort_hash, name)
    if sort_hash[name] == -1
      '<i class="material-icons md-18">keyboard_arrow_down</i>'
    elsif sort_hash[name] == 1
      '<i class="material-icons md-18">keyboard_arrow_up</i>'
    else
      '<i class="material-icons md-18" style="visibility: hidden;">keyboard_arrow_down</i>'
    end
  end
end
