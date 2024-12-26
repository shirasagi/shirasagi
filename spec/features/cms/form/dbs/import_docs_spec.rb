require 'spec_helper'

describe Cms::Form::DocsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:article_node) { create!(:article_node_page, cur_site: site, layout_id: layout) }
  let!(:name) { unique_id }
  let!(:form) { create!(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:col1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, name: 'イベント名',
      input_type: 'text', order: 1)
  end
  let!(:col2) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, name: '緯度',
      input_type: 'text', required: "optional", order: 2)
  end
  let!(:col3) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, name: '経度',
      input_type: 'text', required: "optional", order: 3)
  end
  let!(:col4) do
    create(:cms_column_date_field, cur_site: site, cur_form: form, name: '開始日',
      required: "optional", order: 4)
  end
  let!(:col5) do
    create(:cms_column_date_field, cur_site: site, cur_form: form, name: '終了日',
      required: "optional", order: 5)
  end
  let!(:file) { "#{Rails.root}/spec/fixtures/cms/form_db/pages.csv" }

  before { login_cms_user }

  context 'form_db with full options' do
    let!(:form_db) do
      create(:cms_form_db, cur_site: site, form_id: form.id, node_id: article_node.id,
        import_column_options: { '0': { name: 'イベント名', kind: 'start_with', values: %w(お) } },
        import_page_name: 'イベント名', import_event: 1, import_map: 1)
    end

    it 'import and download' do
      # import
      visit import_cms_form_db_docs_path(site: site.id, db_id: form_db.id)
      expect(current_path).not_to eq sns_login_path

      within "#item-form" do
        attach_file "item[in_file]", file
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.imported")

      pages = form_db.pages
      expect(pages.size).to eq 2

      expect(pages[0].name).to eq 'お正月'
      expect(pages[1].name).to eq 'お盆'

      expect(pages[0].event_dates.present?).to be_truthy
      expect(pages[1].event_dates.present?).to be_falsey

      expect(pages[0].map_points.present?).to be_truthy
      expect(pages[1].map_points.present?).to be_falsey

      # download
      visit download_all_cms_form_db_docs_path(site: site.id, db_id: form_db.id)
      expect(current_path).not_to eq sns_login_path

      # choose 'item[encoding]', option: 'UTF-8'
      click_on I18n.t("ss.links.download")
      wait_for_download

      csv = CSV.read(downloads.first, headers: true)
      expect(csv.length).to eq 2
      expect(csv.to_s).to eq File.read(file)
    end
  end

  context 'form_db without options' do
    let!(:form_db) do
      create(:cms_form_db, cur_site: site, form_id: form.id, node_id: article_node.id,
        import_page_name: nil, import_event: nil, import_map: nil)
    end

    it 'import and download' do
      # import
      visit import_cms_form_db_docs_path(site: site.id, db_id: form_db.id)
      expect(current_path).not_to eq sns_login_path

      within "#item-form" do
        attach_file "item[in_file]", file
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.imported")

      pages = form_db.pages
      expect(pages.size).to eq 2

      expect(pages[0].name).to eq 'お正月'
      expect(pages[1].name).to eq 'お盆'

      expect(pages[0].event_dates.present?).to be_falsey
      expect(pages[1].event_dates.present?).to be_falsey

      expect(pages[0].map_points.present?).to be_falsey
      expect(pages[1].map_points.present?).to be_falsey

      # download
      visit download_all_cms_form_db_docs_path(site: site.id, db_id: form_db.id)
      expect(current_path).not_to eq sns_login_path

      # choose 'item[encoding]', option: 'UTF-8'
      click_on I18n.t("ss.links.download")
      wait_for_download

      csv = CSV.read(downloads.first, headers: true)
      expect(csv.length).to eq 2
      expect(csv.to_s).to eq File.read(file)
    end
  end

  context 'form_db with import_skip_same_file' do
    let!(:form_db) do
      create(:cms_form_db, cur_site: site, form_id: form.id, node_id: article_node.id,
        import_skip_same_file: 1, import_url_hash: file_hash)
    end
    let!(:file_hash) { Digest::MD5.file(file).to_s }
    let!(:in_file) { Fs::UploadedFile.create_from_file(file) }
    let!(:task) { SS::Task.new }

    before do
      def task.log(msg)
        # skip
      end
    end

    it 'not manually (background) import' do
      form_db.import_csv(file: in_file, task: task)
      expect(form_db.pages.size).to eq 0
    end

    it 'manually import' do
      form_db.import_csv(file: in_file, task: task, manually: 1)
      expect(form_db.pages.size).to eq 2
    end
  end
end
