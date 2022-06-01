module Cms::SnsHelper
  def show_line_post_confirm?
    return false if !@item.class.include?(Cms::Addon::LinePoster)

    site = @item.site
    item = (@item.respond_to?(:master) && @item.master) ? @item.master : @item

    return false if !site.line_poster_enabled?
    return false if !@item.use_line_post?

    if @item.line_edit_auto_post_enabled?
      # 再編集が有効の為、すでに投稿済みかをチェックしない。
    else
      return false if item.line_posted.present?
    end

    true
  end

  def show_twitter_post_confirm?
    return false if !@item.class.include?(Cms::Addon::TwitterPoster)

    item = (@item.respond_to?(:master) && @item.master) ? @item.master : @item

    return false if !@item.use_twitter_post?

    if @item.twitter_edit_auto_post_enabled?
      # 再編集が有効の為、すでに投稿済みかをチェックしない。
    else
      return false if item.twitter_posted.present?
    end

    true
  end

  def render_sns_post_confirm
    messages = []
    if show_line_post_confirm?
      messages << t("cms.confirm.line_post_enabled")
    end
    if show_twitter_post_confirm?
      messages << t("cms.confirm.twitter_post_enabled")
    end

    return "" if messages.blank?

    h = []
    h << "<div class=\"sns-post-confirm\">"
    h << "<h2>#{t("cms.confirm.when_publish")}</h2>"
    h << "<ul>"
    messages.each do |message|
      h << ("<li>" + message + "</li>")
    end
    h << "</div>"

    return h.join("\n")
  end
end
