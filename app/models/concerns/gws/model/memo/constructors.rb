module Gws::Model::Memo::Constructors
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def new_reply(item_reply, cur_site:, cur_user:, respond_to: :sender)
      item = new(cur_site: cur_site, cur_user: cur_user)
      item.subject = "Re: #{item_reply.subject}"

      case respond_to
      when :all
        item.to_member_ids = [item_reply.user_id] + item_reply.to_member_ids - [cur_user.id]
        item.to_shared_address_group_ids = item_reply.to_shared_address_groups.readable(cur_user, site: cur_site).pluck(:id)
        item.to_webmail_address_group_ids = item_reply.to_webmail_address_groups.allow(:read, cur_user, site: cur_site).pluck(:id)
        item.cc_member_ids = item_reply.cc_member_ids
        item.cc_shared_address_group_ids = item_reply.cc_shared_address_groups.readable(cur_user, site: cur_site).pluck(:id)
        item.cc_webmail_address_group_ids = item_reply.cc_webmail_address_groups.allow(:read, cur_user, site: cur_site).pluck(:id)
      else # :sender
        item.to_member_ids = [ item_reply.user_id ]
      end

      case item_reply.format
      when 'html'
        item.format = 'html'
        item.html = Gws::Memo.reply_html(item_reply, cur_site: cur_site, cur_user: cur_user)
        text = Gws::Memo.html_to_text(item_reply.html)
        item.text = Gws::Memo.reply_text(item_reply, cur_site: cur_site, cur_user: cur_user, text: text)
      else # 'text'
        item.format = 'text'
        item.text = Gws::Memo.reply_text(item_reply, cur_site: cur_site, cur_user: cur_user)
        html = Gws::Memo.text_to_html(item_reply.text)
        item.html = Gws::Memo.reply_html(item_reply, cur_site: cur_site, cur_user: cur_user, html: html)
      end

      item
    end

    def new_forward(item_forward, cur_site:, cur_user:)
      item = new(cur_site: cur_site, cur_user: cur_user)
      item.subject = "Fwd: #{item_forward.display_subject}"
      item.ref_file_ids = item_forward.file_ids

      case item_forward.format
      when 'html'
        item.format = 'html'
        item.html = Gws::Memo.forward_html(item_forward, cur_site: cur_site, cur_user: cur_user)
        text = Gws::Memo.html_to_text(item_forward.html)
        item.text = Gws::Memo.forward_text(item_forward, cur_site: cur_site, cur_user: cur_user, text: text)
      else # 'text'
        item.format = 'text'
        item.text = Gws::Memo.forward_text(item_forward, cur_site: cur_site, cur_user: cur_user)
        html = Gws::Memo.text_to_html(item_forward.text)
        item.html = Gws::Memo.forward_html(item_forward, cur_site: cur_site, cur_user: cur_user, html: html)
      end

      item
    end
  end
end
