class Article::Page::ExportJob < Cms::ApplicationJob
  include Job::SS::Binding::Task

  self.task_class = Cms::FileGenTask

  def perform
    csv_encoding = task.params.fetch("encoding", "UTF-8") if task.params.present?
    csv_encoding ||= "UTF-8"

    form_id = task.params.fetch("form_id", nil) if task.params.present?
    if form_id.present? && node.respond_to?(:st_forms)
      form = node.st_forms.where(id: form_id).first
    end

    truncate = task.params.fetch("truncate", "no") if task.params.present?
    truncate = truncate != "no" if truncate

    criteria = Article::Page.all
    criteria = criteria.site(site)
    criteria = criteria.node(node) if node
    criteria = criteria.allow(:read, user, site: site, node: node)
    # 効率を優先し id の降順に並べる
    criteria = criteria.reorder(id: -1)

    if form.present?
      criteria = criteria.where(form_id: form)
    else
      criteria = criteria.exists(form_id: false)
    end

    exporter = Cms::PageExporter.new(mode: "article", site: site, truncate: truncate, criteria: criteria)
    task.generated_file_path.tap do |generated_file_path|
      FileUtils.mkdir_p(File.dirname(generated_file_path))
      File.open(generated_file_path, "wb") do |f|
        exporter.enum_csv(encoding: csv_encoding).each do |row|
          f.write(row)
          task.count
        end
      end
    end

    send_notification!
  rescue => _ex
    send_error_notification!
    raise
  end

  private

  def send_notification!
    scheme = site.mypage_scheme.presence || (site.https == "enabled" ? "https" : "http")
    domain = site.mypage_domain.presence || site.domain
    download_url = Rails.application.routes.url_helpers.sns_apis_file_gen_task_download_url(
      protocol: scheme, host: domain, id: task)

    message = SS::Notification.new
    # message.cur_group = site
    message.cur_user = user
    message.member_ids = [ user.id ]
    message.send_date = Time.zone.now
    message.subject = "[#{site.name}] ダウンロード準備完了のお知らせ"
    message.format = 'text'
    message.text = <<~TEXT
      ダウンロードの準備が完了しました。
      下記のURLからダウンロードしてください。

      #{download_url}

      このURLは2週間有効です。
    TEXT

    message.save!
  end

  def send_error_notification!
    message = SS::Notification.new
    message.cur_user = user
    message.member_ids = [ user.id ]
    message.send_date = Time.zone.now
    message.subject = "[#{site.name}] ファイルの準備に失敗しました。"
    message.format = 'text'
    message.text = "ファイルの準備に失敗しました。\nエラーの原因などの詳細はジョブのログを確認してください。"
    message.save!
  end
end
