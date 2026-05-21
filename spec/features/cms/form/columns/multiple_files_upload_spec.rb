require 'spec_helper'

describe Cms::Form::ColumnsController, type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:form) { create(:cms_form, cur_site: site, sub_type: 'entry') }
  let(:name) { unique_id }

  before { login_cms_user }

  context 'basic crud' do
    it do
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/multiple_files_upload') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item).to be_a(Cms::Column::MultipleFilesUpload)
        expect(item.name).to eq name
        expect(item.required).to eq 'required'
        expect(item.file_type).to eq 'image'
      end

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }
      within_dialog do
        find('.save').click
      end
      wait_for_notice I18n.t('ss.notice.saved')

      page.accept_confirm do
        find('.btn-gws-column-item-delete').click
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 0
    end
  end

  context 'public page rendering as image type' do
    let(:layout) { create_cms_layout }
    let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
    let!(:public_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:column) { create(:cms_column_multiple_files_upload, cur_form: public_form, order: 1, file_type: "image") }
    let!(:image1) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let(:header_text) { "詳細については下記の画像をご覧ください。" }
    let!(:article_page) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, form: public_form,
        state: 'public',
        column_values: [
          column.value_type.new(
            column: column,
            header: header_text,
            file_ids: [image1.id.to_s],
            file_labels: { image1.id.to_s => "first-image-alt" }
          )
        ]
      )
    end

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "renders header and image with alt" do
      visit article_page.full_url
      expect(page).to have_css(".images-header", text: header_text)
      expect(page).to have_css("img[alt='first-image-alt']")
    end
  end

  context 'public page rendering as attachment type' do
    let(:layout) { create_cms_layout }
    let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
    let!(:public_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:column) { create(:cms_column_multiple_files_upload, cur_form: public_form, order: 1, file_type: "attachment") }
    let!(:pdf1) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let(:header_text) { "詳細については下記の資料をご確認ください。" }
    let!(:article_page) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, form: public_form,
        state: 'public',
        column_values: [
          column.value_type.new(
            column: column,
            header: header_text,
            file_ids: [pdf1.id.to_s],
            file_labels: { pdf1.id.to_s => "申請書類" }
          )
        ]
      )
    end

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "renders header above the attachment list with link label" do
      visit article_page.full_url
      expect(page).to have_css(".attachment-header", text: header_text)
      expect(page).to have_link("申請書類")
    end
  end

  context 'validation errors' do
    let!(:required_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:image_column) do
      create(:cms_column_multiple_files_upload, cur_form: required_form, order: 1, required: 'required', file_type: "image")
    end
    let!(:attachment_column) do
      create(:cms_column_multiple_files_upload, cur_form: required_form, order: 2, required: 'required', file_type: "attachment")
    end
    let!(:node) { create :article_node_page, cur_site: site }

    it "rejects non-image files when file_type=image" do
      pdf = tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
      article_page = build(
        :article_page, cur_site: site, cur_node: node, form: required_form,
        column_values: [
          image_column.value_type.new(column: image_column, file_ids: [pdf.id.to_s])
        ]
      )
      expect(article_page).not_to be_valid
      expect(article_page.column_values.first.errors[:file_ids]).to include(
        I18n.t("errors.messages.only_image_file", filename: pdf.name)
      )
    end

    it "accepts non-image files when file_type=attachment" do
      pdf = tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
      article_page = build(
        :article_page, cur_site: site, cur_node: node, form: required_form,
        column_values: [
          attachment_column.value_type.new(column: attachment_column, file_ids: [pdf.id.to_s])
        ]
      )
      expect(article_page).to be_valid
    end
  end
end
