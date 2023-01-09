require 'spec_helper'

describe "cms_import", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }
  subject(:index_path) { cms_import_path site.id }
  let(:file) { "#{Rails.root}/spec/fixtures/cms/import/site.zip" }
  let(:name) { File.basename(file, ".*") }
  let(:now) { Time.zone.now.beginning_of_minute }

  context "with auth" do
    before { login_cms_user }

    it "#import" do
      visit index_path
      expect(current_path).to eq index_path

      expectation = expect do
        within "form#task-form" do
          attach_file "item[in_file]", file
          fill_in_datetime 'item[import_date]', with: now
          click_button I18n.t('ss.buttons.import')
        end
      end
      expectation.to have_enqueued_job.exactly(:once)

      enqueued_jobs.first.tap do |enqueued_job|
        expect(enqueued_job[:job]).to eq Cms::ImportFilesJob
        expect(enqueued_job[:args]).to be_blank
        expect(enqueued_job[:at]).to eq now.to_f
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_import'))

      expect(Cms::ImportJobFile.all.count).to eq 1
      Cms::ImportJobFile.first.tap do |task|
        expect(task.import_date).to eq now
        expect(task.node).to be_present
        expect(task.node.route).to eq "cms/import_node"
        expect(task.node.name).to eq name
        expect(task.node.filename).to eq name
        expect(task.file_ids).to have(1).items
      end
    end

    context "with root node" do
      let!(:node) { create :cms_node, filename: "site" }
      let(:error_message) { I18n.t("errors.messages.root_node_save_error") }

      it "#import" do
        visit index_path
        expect(current_path).to eq index_path

        within "form#task-form" do
          attach_file "item[in_file]", file
          fill_in_datetime 'item[import_date]', with: Time.zone.now
          click_button I18n.t('ss.buttons.import')
        end

        expect(enqueued_jobs.size).to eq 0
        expect(current_path).to eq index_path
        expect(page).to have_css("#errorExplanation li", text: error_message)
      end
    end

    context "with max file size" do
      let!(:max) { create :ss_max_file_size, in_size_mb: 0 }
      let(:error_message) do
        filename = "site.zip"
        size = ActiveSupport::NumberHelper.number_to_human_size(::File.size(file))
        limit = ActiveSupport::NumberHelper.number_to_human_size(0)
        I18n.t("errors.messages.too_large_file", filename: filename, size: size, limit: limit)
      end

      it "#import" do
        visit index_path
        expect(current_path).to eq index_path

        within "form#task-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/import/site.zip"
          fill_in_datetime 'item[import_date]', with: Time.zone.now
          click_button I18n.t('ss.buttons.import')
        end

        expect(enqueued_jobs.size).to eq 0
        expect(current_path).to eq index_path
        expect(page).to have_css("#errorExplanation li", text: error_message)
      end
    end
  end
end
