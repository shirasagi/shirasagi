module Gws::Tabular::File::ImportNotification
  extend ActiveSupport::Concern

  def send_notification(result)
    return unless site.notify_model?(Gws::Tabular::File)

    case result
    when :failure
      type = :import_failed
    else # success
      type = :import_succeeded
    end

    fake_item = Gws::Tabular::File[@cur_release].new
    fake_item.cur_site = site
    fake_item.site = site
    fake_item.space = @cur_space
    fake_item.form_id = @cur_release.form_id

    subject = Gws::Tabular::File::NotificationSubjectService.new(site, fake_item, type)
    url_helpers = Rails.application.routes.url_helpers
    path = url_helpers.gws_job_user_log_path(site: site, id: cur_jog_log)
    Gws::Memo::Notifier.deliver_workflow!(
      cur_site: site, cur_user: user, to_users: [ user ], item: fake_item,
      url: path, subject: subject)
  end
end
