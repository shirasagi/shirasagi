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
        accept_confirm do
          click_on I18n.t("gws/workflow.links.download_comment")
        end

        wait_for_download

        csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
        expect(csv.length).to eq 1
        expect(csv[0][Gws::Workflow::File.t(:name)]).to eq item1.name
        expect(csv[0][Gws::Workflow::File.t(:html)]).to eq item1.html
      end
    end

    context "custom form file download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item2.name
        accept_confirm do
          click_on I18n.t("gws/workflow.links.download_comment")
        end

        wait_for_download

        csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
        expect(csv.length).to eq 1
        expect(csv[0][Gws::Workflow::File.t(:name)]).to eq item2.name
        expect(csv[0]["#{form.name}/#{column1.name}"]).to eq column1_value
        expect(csv[0]["#{form.name}/#{column2.name}"]).to eq file2.name
      end
    end

    context "all files download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        find(".gws-workflow .list-head input[type=checkbox]").click

        accept_confirm do
          click_on I18n.t("ss.buttons.csv")
        end

        wait_for_download

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

  context "attachments download" do
    context "basic form file download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item1.name
        accept_confirm do
          click_on I18n.t("gws/workflow.links.download_attachment")
        end

        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(file1.download_filename)
      end
    end

    context "custom form file download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item2.name
        accept_confirm do
          click_on I18n.t("gws/workflow.links.download_attachment")
        end

        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(file2.download_filename)
      end
    end

    context "all files download" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        find(".gws-workflow .list-head input[type=checkbox]").click

        accept_confirm do
          click_on I18n.t("gws/survey.buttons.zip_all_files")
        end

        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(file1.download_filename, file2.download_filename)
      end
    end

    context "too match files to download" do
      let(:file_count) { SS.config.env.deley_download['min_count'].to_i }

      before do
        file_ids = []
        0.upto(file_count - item1.file_ids.length - 1).each do
          file = tmp_ss_file(contents: '0123456789', user: admin)
          file_ids << file.id
        end

        item1.file_ids = item1.file_ids + file_ids
        item1.save!
      end

      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on item1.name
        wait_for_ajax
        accept_confirm do
          click_on I18n.t("gws/workflow.links.download_attachment")
        end
        wait_for_ajax

        expect(page).to have_css('#notice', text: I18n.t('gws.notice.delay_download_with_message').sub(/\n.*$/, ''))
        expect(enqueued_jobs.size).to eq 1
        expect(enqueued_jobs.first[:job]).to eq Gws::CompressJob
      end
    end
  end
end
