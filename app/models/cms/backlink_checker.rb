class Cms::BacklinkChecker
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :id, :submit

  validate :validate_backlink

  private

  def cms_user
    @cms_user ||= cur_user.cms_user
  end

  def permit_edit_cms_ignore_alert?
    cms_user.cms_role_permit_any?(cur_site, "edit_cms_ignore_alert")
  end

  def item
    @item ||= Cms::Page.find(id)
  end

  def contains_urls
    @contains_urls ||= Cms.contains_urls_items(item, site: cur_site)
  end

  def validate_backlink
    # このクラスの目的は、リンク切れが発生する場合に保存処理を中断させることにあり、
    # 被リンクがある場合、別の機能にて被リンク一覧が提供されている。
    return if permit_edit_cms_ignore_alert?
    # ページが非公開の場合、チェックしない。リンク切れのリスクは公開から非公開への場合に発生するため。
    # （差し替えページは非公開のはずなので、以下の条件の第2項は評価されることはないが、保険で置いておく。
    return if item.state == "closed" || item.try(:branch?)
    # 公開保存の場合、チェックしない。リンク切れのリスクは非公開への場合に発生するため。
    return if submit == "publish_save"
    # 被リンクがない場合、警告しない（被リンクの検索は遅いため、一番最後に評価する）。
    return if contains_urls.and_public.blank?

    errors.add :base, I18n.t('ss.confirm.contains_url_expect')
  end
end
