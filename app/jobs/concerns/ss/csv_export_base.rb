#frozen_string_literal: true

module SS::CsvExportBase
  extend ActiveSupport::Concern
  include Job::SS::Binding::Task

  included do
    self.task_class = Cms::FileGenTask
  end

  def perform
    task.update(job_id: job_id)
    enumerator = create_csv_enumerator

    task.generated_file_path.tap do |generated_file_path|
      FileUtils.mkdir_p(File.dirname(generated_file_path))
      File.open(generated_file_path, "wb") do |f|
        enumerator.each do |row|
          f.write(row)
          task.count
        end
      end
    end

    send_notification!
  rescue => _e
    send_error_notification!
    raise
  end

  private

  def create_csv_enumerator
    exporter = create_exporter
    exporter.enum_csv(encoding: csv_encoding)
  end

  def csv_encoding
    "UTF-8"
  end

  def canonical_scheme
    SS.config.gws.canonical_scheme
  end

  def canonical_domain
    SS.config.gws.canonical_domain
  end

  def notification_subject
    raise NotImplementedError, "サブクラスで実装してください"
  end

  def send_notification!
    return unless respond_to?(:user)
    return unless user

    download_url = Rails.application.routes.url_helpers.sns_apis_file_gen_task_download_url(
      protocol: canonical_scheme, host: canonical_domain, id: task)

    message = SS::Notification.new
    message.cur_user = user
    message.member_ids = [ user.id ]
    message.send_date = Time.zone.now
    message.subject = notification_subject
    message.format = 'text'
    message.text = <<~TEXT
      ダウンロードの準備が完了しました。
      下記のURLからダウンロードしてください。

      #{download_url}

      このURLは14日間有効です。
    TEXT

    message.save!
  end

  def send_error_notification!
    return unless respond_to?(:user)
    return unless user

    message = SS::Notification.new
    message.cur_user = user
    message.member_ids = [ user.id ]
    message.send_date = Time.zone.now
    if respond_to?(:site) && site
      message.subject = "[#{site.name}] CSVの準備に失敗しました。"
    else
      message.subject = "CSVの準備に失敗しました。"
    end
    message.format = 'text'
    message.text = "CSVの準備に失敗しました。\nエラーの原因などの詳細はジョブのログを確認してください。"
    message.save!
  end
end
