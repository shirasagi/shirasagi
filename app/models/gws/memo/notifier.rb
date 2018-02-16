class Gws::Memo::Notifier
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_group, :cur_user, :to_users, :item, :item_title, :item_text
  attr_accessor :subject, :text

  class << self
    def deliver!(opts)
      new(opts).deliver!
    end

    def deliver_workflow_request!(opts)
      opts = opts.dup

      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      cur_user = opts[:cur_user]
      item = opts[:item]
      from = item.try(:workflow_user) || cur_user

      title = "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{cur_site.name}"

      text = []
      text << "#{from.name}さんより次の記事について承認依頼が届きました。"
      text << "承認作業を行ってください。\n"

      text << "- タイトル"
      text << "  #{item.name}\n"

      text << "- 申請者コメント" if comment.present?
      text << "  #{comment}\n" if comment.present?

      text << "- 記事URL"
      text << "  #{url}\n"

      opts[:item_title] = title
      opts[:item_text] = text.join("\n")

      new(opts).deliver!
    end

    def deliver_workflow_approve!(opts)
      opts = opts.dup

      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      item = opts[:item]

      title = "[#{I18n.t('workflow.mail.subject.approve')}]#{item.name} - #{cur_site.name}"
      text = <<-TEXT
      次の申請が承認されました。

      - タイトル
        #{item.name}

      - 記事URL
        #{url}
      TEXT

      opts[:item_title] = title
      opts[:item_text] = text

      new(opts).deliver!
    end

    def deliver_workflow_remand!(opts)
      opts = opts.dup

      url = opts.delete(:url)
      comment = opts.delete(:comment)
      cur_site = opts[:cur_site]
      cur_user = opts[:cur_user]
      item = opts[:item]

      title = "[#{I18n.t('workflow.mail.subject.remand')}]#{item.name} - #{cur_site.name}"
      text = <<-TEXT
      #{cur_user.name}さんより次の申請について承認依頼が差し戻されました。
      適宜修正を行い、再度承認依頼を行ってください。

      - タイトル
        #{item.name}

      - 差し戻しコメント
        #{comment}

      - 記事URL
        #{url}
      TEXT

      opts[:item_title] = title
      opts[:item_text] = text

      new(opts).deliver!
    rescue => e
      Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise
    end
  end

  def item_title
    @item_title ||= begin
      title = item.try(:topic).try(:name)
      title ||= item.try(:schedule).try(:name)
      title ||= item.try(:_parent).try(:name)
      title ||= item.try(:name)
      title
    end
  end

  def item_text
    @item_text ||= begin
      text = item.try(:text)
      text ||= begin
        html = item.try(:html).presence
        ApplicationController.helpers.sanitize(html, tags: []) if html
      end
      text = text.truncate(60) if text
      text
    end
  end

  def deliver!
    cur_user.cur_site ||= cur_group

    message = Gws::Memo::Notice.new
    message.cur_site = cur_site
    message.cur_user = cur_user
    message.member_ids = to_users.pluck(:id)

    message.send_date = Time.zone.now

    message.subject = subject || I18n.t("gws_notification.#{i18n_key}.subject", name: item_title, default: item_title)
    message.format = 'text'
    message.text = text || I18n.t("gws_notification.#{i18n_key}.text", name: item_title, text: item_text, default: item_text)

    message.save!
  end

  private

  def from_user
    @from_user ||= begin
      user = cur_site.sender_user
      user ||= cur_user
      user
    end
  end

  def i18n_key
    @i18n_key ||= item.class.model_name.i18n_key
  end
end
