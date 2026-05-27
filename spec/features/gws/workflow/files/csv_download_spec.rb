require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:admin) { gws_user }
  let(:form) { create(:gws_workflow_form, state: "public", agent_state: "enabled") }
  let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
  let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form) }

  let(:column1_value) { unique_id }
  let(:file1) { tmp_ss_file(contents: '0123456789', user: admin) }
  let(:file2) { tmp_ss_file(contents: '0123456789', user: admin) }

  let!(:item1) { create :gws_workflow_file, file_ids: [ file1.id ] }
  let!(:item2) do
    Gws::Workflow::File.create!(
      cur_site: site, cur_user: admin, name: "name-#{unique_id}", cur_form: form,
      column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ file2.id ]) ]
    )
  end

  before do
    login_gws_user
  end

  context "csv download" do
    context "basic form file download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item1.name
        wait_for_js_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_comment")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
          expect(csv.length).to eq 1
          expect(csv[0][Gws::Workflow::File.t(:name)]).to eq item1.name
          expect(csv[0][Gws::Workflow::File.t(:html)]).to eq item1.html
        end

        # wait workflow route shown to avoid causing exceptions
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end

    context "custom form file download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item2.name
        wait_for_js_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_comment")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
          expect(csv.length).to eq 1
          expect(csv[0][Gws::Workflow::File.t(:name)]).to eq item2.name
          expect(csv[0]["#{form.name}/#{column1.name}"]).to eq column1_value
          expect(csv[0]["#{form.name}/#{column2.name}"]).to eq file2.name
        end

        # wait workflow route shown to avoid causing exceptions
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end

    context "all files download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        wait_for_event_fired("ss:checked-all-list-items") { find(".gws-workflow .list-head input[type=checkbox]").click }

        accept_confirm do
          click_on I18n.t("ss.buttons.csv")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
          expect(csv.length).to eq 2
          expect(csv[0][Gws::Workflow::File.t(:name)]).to eq item2.name
          expect(csv[0]["#{form.name}/#{column1.name}"]).to eq column1_value
          expect(csv[0]["#{form.name}/#{column2.name}"]).to eq file2.name
          expect(csv[1][Gws::Workflow::File.t(:name)]).to eq item1.name
          expect(csv[1][Gws::Workflow::File.t(:html)]).to eq item1.html
        end
      end
    end
  end

  context "attachments download" do
    context "basic form file download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item1.name
        wait_for_js_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_attachment")
        end

        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(file1.download_filename)

        # wait workflow route shown to avoid causing exceptions
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end

    context "custom form file download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item2.name
        wait_for_js_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_attachment")
        end

        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(file2.download_filename)

        # wait workflow route shown to avoid causing exceptions
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end

    context "all files download on the fly" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        wait_for_event_fired("ss:checked-all-list-items") { find(".gws-workflow .list-head input[type=checkbox]").click }

        accept_confirm do
          click_on I18n.t("gws/survey.buttons.zip_all_files")
        end

        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to have(2).items
        expect(entry_names).to include(file1.download_filename, file2.download_filename)
      end
    end

    context "all files download with job" do
      before do
        @save_min_filesize = Gws::Compressor.min_filesize
        @save_min_count = Gws::Compressor.min_count

        Gws::Compressor.min_filesize = 0
        Gws::Compressor.min_count = 0
      end

      after do
        Gws::Compressor.min_filesize = @save_min_filesize
        Gws::Compressor.min_count = @save_min_count
      end

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it do
        visit gws_workflow_files_path(site: site, state: "all")
        wait_for_event_fired("ss:checked-all-list-items") { find(".gws-workflow .list-head input[type=checkbox]").click }

        accept_confirm do
          click_on I18n.t("gws/survey.buttons.zip_all_files")
        end
        wait_for_notice I18n.t('gws.notice.delay_download_with_message').split(/\R/).first

        expect(Job::Log.all.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        zip_file_path = nil
        expect(SS::Notification.all.count).to eq 1
        SS::Notification.all.first.tap do |notification|
          expect(notification.member_ids).to include(gws_user.id)
          expect(notification.subject).to eq I18n.t("gws/share.mailers.compressed.subject", locale: :ja)
          expect(notification.format).to eq 'text'
          expect(notification.text).to include("ダウンロードの準備が完了しました。")

          match_data = notification.text.match(/^https?:\/\/\w+.+$/mi)
          if match_data
            zip_file_path = match_data.to_s
            zip_file_path = Addressable::URI.parse(zip_file_path).path
            zip_file_path = File.basename(zip_file_path)
          end
        end

        zip_file = SS::DownloadJobFile.find(gws_user, zip_file_path)
        entry_names = ::Zip::File.open(zip_file.path) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to have(2).items
        expect(entry_names).to include(file1.download_filename, file2.download_filename)
      end
    end

    context "too match files to download" do
      before do
        @save_min_filesize = Gws::Compressor.min_filesize
        @save_min_count = Gws::Compressor.min_count

        Gws::Compressor.min_filesize = 0
        Gws::Compressor.min_count = 0
      end

      after do
        Gws::Compressor.min_filesize = @save_min_filesize
        Gws::Compressor.min_count = @save_min_count
      end

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item1.name
        wait_for_js_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_attachment")
        end
        wait_for_notice I18n.t('gws.notice.delay_download_with_message').split(/\R/).first

        # wait workflow route shown to avoid causing exceptions
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        expect(Job::Log.all.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        zip_file_path = nil
        expect(SS::Notification.all.count).to eq 1
        SS::Notification.all.first.tap do |notification|
          expect(notification.member_ids).to include(gws_user.id)
          expect(notification.subject).to eq I18n.t("gws/share.mailers.compressed.subject", locale: :ja)
          expect(notification.format).to eq 'text'
          expect(notification.text).to include("ダウンロードの準備が完了しました。")

          match_data = notification.text.match(/^https?:\/\/\w+.+$/mi)
          if match_data
            zip_file_path = match_data.to_s
            zip_file_path = Addressable::URI.parse(zip_file_path).path
            zip_file_path = File.basename(zip_file_path)
          end
        end

        zip_file = SS::DownloadJobFile.find(gws_user, zip_file_path)
        entry_names = ::Zip::File.open(zip_file.path) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to have(1).items
        expect(entry_names).to include(file1.download_filename)
      end
    end
  end
end
