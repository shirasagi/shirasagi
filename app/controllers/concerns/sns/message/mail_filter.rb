module Sns::Message::MailFilter
  extend ActiveSupport::Concern

  private
    def send_notification_mail(post)
      thread = post.thread
      url = sns_message_thread_posts_url(thread_id: thread.id)

      thread.other_active_members(@cur_user).each do |user|
        next if user.email.blank?

        send_params = {
          from: "shirasagi@#{request.domain}",
          to: user.email,
          subject: "[#{SS.config.ss.application_name}] " + I18n.t("sns/message.mail_templates.notification.subject", user: @cur_user.name),
          body: I18n.t("sns/message.mail_templates.notification.text", text: post.text, url: url)
        }
        SS::Mailer.new_message(send_params).deliver_now
      end
    end
end
