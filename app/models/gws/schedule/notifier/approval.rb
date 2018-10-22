class Gws::Schedule::Notifier::Approval
  class << self
    def deliver_request!(opts)
      return unless opts[:cur_site].notify_model?(opts[:item].class)
      return unless opts[:to_users].present?

      opts = opts.dup
      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      cur_user = opts[:cur_user]
      item = opts[:item]
      from = item.try(:workflow_user) || cur_user

      text = []
      text << "#{item.name}\n#{url}\n"
      text << "- 申請者コメント\n#{comment}\n" if comment.present?

      i18n_key = "#{item.class.model_name.i18n_key}/approval/request"
      opts[:subject] = I18n.t("gws_notification.#{i18n_key}.subject", name: item.name)
      opts[:text] = I18n.t("gws_notification.#{i18n_key}.text", from: from.name, text: "#{url}")
      Gws::Memo::Notifier.new(opts).deliver!
    end

    def deliver_approve!(opts)
      return unless opts[:cur_site].notify_model?(opts[:item].class)
      return unless opts[:to_users].present?

      opts = opts.dup
      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      cur_user = opts[:cur_user]
      item = opts[:item]
      from = item.try(:workflow_user) || cur_user

      text = []
      text << "#{item.name}\n#{url}\n"
      text << "--- 承認コメント ---\n#{comment}\n" if comment.present?

      i18n_key = "#{item.class.model_name.i18n_key}/approval/approve"
      opts[:subject] = I18n.t("gws_notification.#{i18n_key}.subject", name: item.name)
      opts[:text] = I18n.t("gws_notification.#{i18n_key}.text", from: from.name, text: "#{url}")
      Gws::Memo::Notifier.new(opts).deliver!
    end

    def deliver_remand!(opts)
      return unless opts[:cur_site].notify_model?(opts[:item].class)
      return unless opts[:to_users].present?

      opts = opts.dup
      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      cur_user = opts[:cur_user]
      item = opts[:item]
      from = item.try(:workflow_user) || cur_user

      text = []
      text << "#{item.name}\n#{url}\n"
      text << "--- 差し戻しコメント ---\n#{comment}\n" if comment.present?

      i18n_key = "#{item.class.model_name.i18n_key}/approval/remand"
      opts[:subject] = I18n.t("gws_notification.#{i18n_key}.subject", name: item.name, from: from.name)
      opts[:text] = I18n.t("gws_notification.#{i18n_key}.text", from: from.name, text: "#{url}")
      Gws::Memo::Notifier.new(opts).deliver!
    end
  end
end
