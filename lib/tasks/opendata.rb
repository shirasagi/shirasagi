module Tasks
  module Opendata
    class << self
      ALL_DOWNLOAD_REPORT_PROMPT = <<~PROMPT.freeze
        ダウンロード履歴からダウンロード数レポートを作成します。
        溜まっているダウンロード履歴の件数によって処理に要する時間が長くなり、
        場合によっては1日以上の時間を要する場合がありますが、
        実行してよろしいですか？ [y|N]:
      PROMPT

      ALL_ACCESS_REPORT_PROMPT = <<~PROMPT.freeze
        アクセス履歴からアクセス数レポートを作成します。
        溜まっているアクセス履歴の件数によって処理に要する時間が長くなり、
        場合によっては1日以上の時間を要する場合がありますが、
        実行してよろしいですか？ [y|N]:
      PROMPT

      ALL_PREVIEW_REPORT_PROMPT = <<~PROMPT.freeze
        プレビュー履歴からプレビュー数レポートを作成します。
        溜まっているプレビュー履歴の件数によって処理に要する時間が長くなり、
        場合によっては1日以上の時間を要する場合がありますが、
        実行してよろしいですか？ [y|N]:
      PROMPT

      ALL_DOWNLOAD_HISTORY_PROMPT = <<~PROMPT.freeze
        ダウンロード履歴のアーカイブを作成し、アーカイブ化したダウンロード履歴をデータベースから削除します。
        溜まっているダウンロード履歴の件数によって処理に要する時間が長くなり、
        場合によっては1日以上の時間を要する場合がありますが、
        実行してよろしいですか？ [y|N]:
      PROMPT

      ALL_PREVIEW_HISTORY_PROMPT = <<~PROMPT.freeze
        プレビュー履歴のアーカイブを作成し、アーカイブ化したプレビュー履歴をデータベースから削除します。
        溜まっているプレビュー履歴の件数によって処理に要する時間が長くなり、
        場合によっては1日以上の時間を要する場合がありますが、
        実行してよろしいですか？ [y|N]:
      PROMPT

      def generate_all_download_report(site)
        confirm = ask(ALL_DOWNLOAD_REPORT_PROMPT)
        return unless confirm.match?(/^[yY]/)

        create_resource_download_reports(site)
        set_deleted_to_resource_download_reports(site)
      end

      def generate_all_access_report(site)
        confirm = ask(ALL_ACCESS_REPORT_PROMPT)
        return unless confirm.match?(/^[yY]/)

        create_dataset_access_reports(site)
        set_deleted_to_dataset_access_reports(site)
      end

      def generate_all_preview_report(site)
        confirm = ask(ALL_PREVIEW_REPORT_PROMPT)
        return unless confirm.match?(/^[yY]/)

        create_resource_preview_reports(site)
        set_deleted_to_resource_preview_reports(site)
      end

      def archive_all_download_history(site)
        confirm = ask(ALL_DOWNLOAD_HISTORY_PROMPT)
        return unless confirm.match?(/^[yY]/)

        min_downloaded = [
          ::Opendata::ResourceDownloadHistory.site(site).min(:downloaded),
          ::Opendata::ResourceDatasetDownloadHistory.site(site).min(:downloaded),
          ::Opendata::ResourceBulkDownloadHistory.site(site).min(:downloaded)
        ].compact.min
        return if min_downloaded.blank?

        job = ::Opendata::ResourceDownloadHistoryArchiveJob.bind(site_id: site.id)

        min_downloaded = min_downloaded.in_time_zone
        target = min_downloaded.beginning_of_month
        today = Time.zone.now.beginning_of_day
        loop do
          break if target > today

          benchmark("archiving resource download histories for #{target.strftime("%Y/%m")}") do
            job.perform_now(now: target.end_of_month.strftime("%Y/%m/%d"))
          end

          target += 1.month
        end

        # last
        job.perform_now
      end

      def archive_all_preview_history(site)
        confirm = ask(ALL_PREVIEW_HISTORY_PROMPT)
        return unless confirm.match?(/^[yY]/)

        min_previewed = ::Opendata::ResourcePreviewHistory.all.site(site).min(:previewed)
        return if min_previewed.blank?

        job = ::Opendata::ResourcePreviewHistoryArchiveJob.bind(site_id: site.id)

        min_previewed = min_previewed.in_time_zone
        target = min_previewed.beginning_of_month
        today = Time.zone.now.beginning_of_day
        loop do
          break if target > today

          benchmark("archiving resource preview histories for #{target.strftime("%Y/%m")}") do
            job.perform_now(now: target.end_of_month.strftime("%Y/%m/%d"))
          end

          target += 1.month
        end

        # last
        job.perform_now
      end

      private

      def ask(prompt)
        print prompt.strip
        STDIN.gets
      end

      def benchmark(title)
        STDOUT.write title
        STDOUT.write " .. "
        ret = nil
        time = Benchmark.realtime do
          ret = yield
        end
        STDOUT.puts "Completed in #{time} secs"

        ret
      end

      def each_opendata_site(&block)
        all_site_ids = ::Opendata::Dataset.all.pluck(:site_id).uniq
        return if all_site_ids.blank?

        all_site_ids.each_slice(20) do |site_ids|
          sites = Cms::Site.all.in(id: site_ids).to_a
          sites.each(&block)
        end
      end

      def create_resource_download_reports(site)
        min_downloaded = [
          ::Opendata::ResourceDownloadHistory.site(site).min(:downloaded),
          ::Opendata::ResourceDatasetDownloadHistory.site(site).min(:downloaded),
          ::Opendata::ResourceBulkDownloadHistory.site(site).min(:downloaded)
        ].compact.min
        return if min_downloaded.blank?

        job = ::Opendata::ResourceDownloadReportJob.bind(site_id: site.id)

        min_downloaded = min_downloaded.in_time_zone
        target = min_downloaded.beginning_of_month
        today = Time.zone.now.beginning_of_day
        loop do
          break if target > today

          benchmark("creating resource download reports for #{target.strftime("%Y/%m")}") do
            job.perform_now(target.strftime("%Y/%m/%d"), target.end_of_month.strftime("%Y/%m/%d"))
          end

          target += 1.month
        end

        # last
        job.perform_now
      end

      def set_deleted_to_resource_download_reports(site)
        benchmark("setting \"deleted\" to resource download reports") do
          dataset_and_resources = ::Opendata::Dataset.site(site).pluck(:id, "resources._id")
          dataset_and_resources.map! do |dataset_id, resources|
            if resources.blank?
              [ [ dataset_id, -1 ] ]
            else
              resources.map { |hash| [ dataset_id, hash["_id"] ] }
            end
          end
          dataset_and_resources.flatten!(1)

          criteria = ::Opendata::ResourceDownloadReport.site(site).exists(deleted: false)
          all_ids = criteria.pluck(:id)
          all_ids.each_slice(100) do |ids|
            reports = criteria.in(id: ids).to_a
            reports.each do |report|
              found = dataset_and_resources.find do |dataset_id, resource_id|
                report.dataset_id == dataset_id && report.resource_id == resource_id
              end
              next if found.present?

              report.update(deleted: ::Opendata::ResourceDownloadReport::UNCERTAIN_DELETED_TIME)
            end
          end
        end
      end

      def create_dataset_access_reports(site)
        min_created = ::Recommend::History::Log.all.site(site).min(:created)
        return if min_created.blank?

        job = ::Opendata::DatasetAccessReportJob.bind(site_id: site.id)

        min_created = min_created.in_time_zone
        target = min_created.beginning_of_month
        today = Time.zone.now.beginning_of_day
        loop do
          break if target > today

          benchmark("creating dataset access reports for #{target.strftime("%Y/%m")}") do
            job.perform_now(target.strftime("%Y/%m/%d"), target.end_of_month.strftime("%Y/%m/%d"))
          end

          target += 1.month
        end

        # last
        job.perform_now
      end

      def set_deleted_to_dataset_access_reports(site)
        benchmark("setting \"deleted\" to dataset access reports") do
          dataset_ids = ::Opendata::Dataset.site(site).pluck(:id)

          criteria = ::Opendata::DatasetAccessReport.site(site).exists(deleted: false)
          all_ids = criteria.pluck(:id)
          all_ids.each_slice(100) do |ids|
            reports = criteria.in(id: ids).to_a
            reports.each do |report|
              next if dataset_ids.include?(report.dataset_id)

              report.update(deleted: ::Opendata::DatasetAccessReport::UNCERTAIN_DELETED_TIME)
            end
          end
        end
      end

      def create_resource_preview_reports(site)
        min_previewed = ::Opendata::ResourcePreviewHistory.all.site(site).min(:previewed)
        return if min_previewed.blank?

        job = ::Opendata::ResourcePreviewReportJob.bind(site_id: site.id)

        min_previewed = min_previewed.in_time_zone
        target = min_previewed.beginning_of_month
        today = Time.zone.now.beginning_of_day
        loop do
          break if target > today

          benchmark("creating resource preview reports for #{target.strftime("%Y/%m")}") do
            job.perform_now(target.strftime("%Y/%m/%d"), target.end_of_month.strftime("%Y/%m/%d"))
          end

          target += 1.month
        end

        # last
        job.perform_now
      end

      def set_deleted_to_resource_preview_reports(site)
        benchmark("setting \"deleted\" to resource preview reports") do
          dataset_and_resources = ::Opendata::Dataset.site(site).pluck(:id, "resources._id")
          dataset_and_resources.map! do |dataset_id, resources|
            if resources.blank?
              [ [ dataset_id, -1 ] ]
            else
              resources.map { |hash| [ dataset_id, hash["_id"] ] }
            end
          end
          dataset_and_resources.flatten!(1)

          criteria = ::Opendata::ResourcePreviewReport.site(site).exists(deleted: false)
          all_ids = criteria.pluck(:id)
          all_ids.each_slice(100) do |ids|
            reports = criteria.in(id: ids).to_a
            reports.each do |report|
              found = dataset_and_resources.find do |dataset_id, resource_id|
                report.dataset_id == dataset_id && report.resource_id == resource_id
              end
              next if found.present?

              report.update(deleted: ::Opendata::ResourcePreviewReport::UNCERTAIN_DELETED_TIME)
            end
          end
        end
      end
    end
  end
end
