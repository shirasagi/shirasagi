module Opendata::Metadata::CsvImporter
  extend ActiveSupport::Concern

  private

  def import_from_csv
    put_log("import from #{source_url}")

    if reports.count >= 5
      reports.order_by(created: 1).first.destroy
    end

    @report = Opendata::Metadata::Importer::Report.new(cur_site: site, importer: self)
    @report.save!

    opts = {}
    opts[:http_basic_authentication] = [basicauth_username, basicauth_password] if basicauth_enabled?

    imported_dataset_ids = []
    updated_dataset_ids = []
    skipped_dataset_ids = []
    error_dataset_names = []
    imported_resource_ids = []
    notice_body = []

    begin
      Tempfile.create('import_csv') do |tempfile|
        ::URI.open(source_url, opts) do |res|
          IO.copy_stream(res, tempfile.path)
          put_log('[Download] ' + tempfile.size.to_s(:delimited) + ' bytes')
          put_log('[Import] start')
          SS::Csv.foreach_row(tempfile.path, headers: true) do |csv_row, idx|
            begin
              name = (csv_row['データセット_タイトル'].presence || csv_row['データ名称']).to_s.gsub(/\R|\s|\u00A0|　/, '')

              put_log("- #{idx + 1} #{name}")

              @report_dataset = @report.new_dataset

              attributes = JSON.parse(csv_row.to_h.to_json)

              metadata_dataset_id = (csv_row['データセット_ID'].presence || csv_row['NO']).to_s.gsub(/\R|\s|\u00A0|　/, '')
              dataset = ::Opendata::Dataset.node(node).
                where(metadata_importer_id: id, metadata_dataset_id: metadata_dataset_id).
                first
              dataset ||= ::Opendata::Dataset.new

              dataset.cur_site = site
              dataset.cur_node = node
              def dataset.set_updated; end

              dataset.layout = node.page_layout || node.layout
              dataset.name = name
              dataset.text = csv_row['データセット_概要'].presence || csv_row['データ概要']
              dataset.group_ids = group_ids

              dataset.created = Time.zone.parse(csv_row['データセット_公開日'].presence || csv_row['登録日']) rescue Time.zone.now
              dataset.updated = Time.zone.parse(csv_row['データセット_最終更新日'].presence || csv_row['最終更新日']) rescue dataset.created
              dataset.released = dataset.created

              dataset.metadata_importer = self
              dataset.metadata_host = source_host
              dataset.metadata_dataset_id = metadata_dataset_id
              dataset.metadata_japanese_local_goverment_code = csv_row['全国地方公共団体コード'].presence ||
                csv_row['都道府県コード又は市区町村コード']
              dataset.metadata_local_goverment_name = csv_row['地方公共団体名'].presence ||
                (csv_row['都道府県名'].to_s + csv_row['市区町村名'].to_s)
              dataset.metadata_dataset_keyword = csv_row['データセット_キーワード'].to_s.gsub(';', ',')
              dataset.metadata_dataset_released = dataset.created
              dataset.metadata_dataset_updated = dataset.updated
              dataset.metadata_dataset_url = csv_row['データセット_URL'].presence || csv_row['URL']
              dataset.metadata_dataset_update_frequency = csv_row['データセット_更新頻度'].presence || csv_row['更新頻度']
              dataset.metadata_dataset_follow_standards = csv_row['データセット_準拠する標準']
              dataset.metadata_dataset_related_document = csv_row['データセット_関連ドキュメント']
              dataset.metadata_dataset_target_period = csv_row['データセット_対象期間']
              dataset.metadata_dataset_contact_name = csv_row['データセット_連絡先名称']
              dataset.metadata_dataset_contact_email = csv_row['データセット_連絡先メールアドレス']
              dataset.metadata_dataset_contact_tel = csv_row['データセット_連絡先電話番号']
              dataset.metadata_dataset_contact_ext = csv_row['データセット_連絡先内線番号']
              dataset.metadata_dataset_contact_form_url = csv_row['データセット_連絡先FormURL']
              dataset.metadata_dataset_contact_remark = csv_row['データセット_連絡先備考（その他、SNSなど）']
              dataset.metadata_dataset_remark = csv_row['データセット_備考'].presence || csv_row['備考']

              dataset.metadata_imported_url = source_url
              dataset.metadata_imported_attributes = attributes
              dataset.metadata_source_url = dataset.metadata_dataset_url
              dataset.state = "public"

              if dataset.updated_changed?
                put_log("- dataset : #{dataset.new_record? ? "create" : "update"} #{dataset.name}")
                # notice_body << "#{idx + 2}行目 #{dataset.name} : #{dataset.new_record? ? "作成" : "更新"}"
                dataset.save!
                updated_dataset_ids << dataset.id if !updated_dataset_ids.include?(dataset.id)
              elsif !updated_dataset_ids.include?(dataset.id)
                put_log("- dataset : skip #{dataset.name}")
                # notice_body << "#{idx + 2}行目 #{dataset.name} : --"
                skipped_dataset_ids << dataset.id if !skipped_dataset_ids.include?(dataset.id)
              end

              @report_dataset.set_reports(dataset, attributes, source_url, idx)

              imported_dataset_ids << dataset.id

              license_id = csv_row['ファイル_ライセンス'].to_s.presence || csv_row['ライセンス'].to_s
              license = get_license_from_metadata_uid(license_id)
              put_log("could not found license #{license_id}") if license.nil?

              url = csv_row['ファイル_ダウンロードURL']
              if url.present?
                begin
                  @report_resource = @report_dataset.new_resource

                  resource = dataset.resources.select { |r| r.source_url == url }.first

                  if resource.nil?
                    resource = Opendata::Resource.new
                    dataset.resources << resource
                  end

                  filename = csv_row['ファイル_タイトル'].to_s + ::File.extname(url.to_s)
                  format = csv_row['ファイル形式']
                  format = ::File.extname(url.to_s).delete(".").sub(/\?.*$/, "").downcase if format.blank?
                  format = "html" if format.blank?

                  resource.source_url = url
                  resource.name = csv_row['ファイル_タイトル'].presence || filename
                  resource.text = csv_row['ファイル_説明']
                  resource.filename = filename
                  resource.format = format
                  resource.license = license
                  # resource.original_url = url
                  # resource.original_updated = Time.zone.parse(csv_row['ファイル_最終更新日']) rescue dataset.updated
                  # resource.crawl_update = 'auto'

                  def resource.set_updated; end

                  resource.updated = Time.zone.parse(csv_row['ファイル_最終更新日']) rescue dataset.updated
                  # resource.updated = resource.original_updated
                  resource.created = Time.zone.parse(csv_row['ファイル_公開日']) rescue dataset.created

                  resource.metadata_importer = self
                  resource.metadata_host = source_host

                  resource.metadata_imported ||= Time.zone.now
                  resource.metadata_imported_url = source_url
                  resource.metadata_imported_attributes = attributes

                  resource.metadata_file_access_url = csv_row['ファイル_アクセスURL']
                  resource.metadata_file_download_url = csv_row['ファイル_ダウンロードURL']
                  resource.metadata_file_released = resource.created
                  resource.metadata_file_updated = resource.updated
                  resource.metadata_file_terms_of_service = csv_row['ファイル_利用規約']
                  resource.metadata_file_related_document = csv_row['ファイル_関連ドキュメント']
                  resource.metadata_file_follow_standards = csv_row['ファイル_準拠する標準']

                  if resource.updated_changed?
                    put_log("-- resource : #{resource.new_record? ? "create" : "update"} #{resource.name}")
                    # notice_body << "#{idx + 2}行目 #{resource.name} : #{resource.new_record? ? "作成" : "更新"}"
                    resource.save!
                  else
                    put_log("-- resource : skip #{resource.name}")
                    # notice_body << "#{idx + 2}行目 #{resource.name} : --"
                  end

                  imported_resource_ids << resource.id

                  @report_resource.set_reports(resource, attributes, idx)
                rescue => e
                  message = "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
                  put_log(message)
                  notice_body << "#{idx + 2}行目 #{resource.name} : #{e.message}"
                  error_dataset_names << dataset.name

                  @report_resource.add_error(message)
                ensure
                  @report_resource.save!
                end
              end

              if dataset.updated_changed?
                dataset.metadata_imported ||= Time.zone.now
                set_relation_ids(dataset)
              end

              @report_dataset.set_reports(dataset, attributes, source_url, idx)
            rescue => e
              message = "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
              put_log(message)
              notice_body << "#{idx + 2}行目 #{dataset.name} : #{e.message}"
              error_dataset_names << dataset.name

              @report_dataset.add_error(message) if @report_dataset.present?
            ensure
              @report_dataset.save! if @report_dataset.present?
            end
          end
          put_log('[Import] finished')
        end
      end
    rescue => e
      put_log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    end

    body = []
    url = ::File.join(
      site.mypage_full_url,
      Rails.application.routes.url_helpers.opendata_metadata_importer_path(site: site.id, cid: node.id, id: id)
    )
    if error_dataset_names.present?
      @report.notice_subject = "#{site.name} #{name}【エラー通知】"
      body << "取り込み時にエラーが発生しました。"
      body << "下記のエラーを確認し、修正してください。"
      body << notice_body.join("\n")
      body << url
      @report.notice_body = body.join("\n")
    else
      # destroy unimported datasets
      dataset_ids = ::Opendata::Dataset.site(site).node(node).where(
        "metadata_importer_id" => id
      ).pluck(:id)
      # dataset_ids -= imported_dataset_ids
      dataset_ids.each do |id|
        dataset = ::Opendata::Dataset.find(id) rescue nil
        next unless dataset

        if imported_dataset_ids.include?(id)
          dataset.resources.each do |resource|
            next if imported_resource_ids.include?(resource.id)
            put_log("-- resource : destroy #{resource.name}")
            resource.destroy
          end
        else
          put_log("- dataset : destroy #{dataset.name}")
          dataset.destroy
        end
      end

      @report.notice_subject = "#{site.name} #{name}【更新通知】"
      body << "#{I18n.l(@report.created, format: :long)}に、CSVの取り込みを実施しました。"
      if updated_dataset_ids.present?
        body << "#{updated_dataset_ids.count}件のデータセットを更新しました。"
      end
      if skipped_dataset_ids.present?
        body << "#{skipped_dataset_ids.count}件のデータセットは更新しませんでした。"
      end
      # body << notice_body.join("\n")
      body << url
      @report.notice_body = body.join("\n")
    end

    @report.save!
  end
end
