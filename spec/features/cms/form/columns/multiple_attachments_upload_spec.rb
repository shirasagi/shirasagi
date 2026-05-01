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
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/multiple_attachments_upload') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item).to be_a(Cms::Column::MultipleAttachmentsUpload)
        expect(item.name).to eq name
        expect(item.required).to eq 'required'
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

  context 'public page rendering with header and multiple attachments' do
    let(:layout) { create_cms_layout }
    let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
    let!(:public_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:column) { create(:cms_column_multiple_attachments_upload, cur_form: public_form, order: 1) }
    let!(:pdf1) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let!(:pdf2) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf",
        basename: "second-#{unique_id}.pdf",
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
            file_ids: [pdf1.id.to_s, pdf2.id.to_s],
            file_labels: {
              pdf1.id.to_s => "申請書類",
              pdf2.id.to_s => "案内資料"
            }
          )
        ]
      )
    end

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "renders the header above the attachment list with link labels in order" do
      article_page.reload
      cloned_ids = article_page.column_values.first.file_ids
      expect(cloned_ids.length).to eq 2

      visit article_page.full_url
      expect(page).to have_css(".attachment-header", text: header_text)
      expect(page).to have_link("申請書類")
      expect(page).to have_link("案内資料")
      # 並び順が維持されていること
      expect(page.body.index("申請書類")).to be < page.body.index("案内資料")
    end
  end

  context 'validation errors' do
    let!(:required_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:required_column) do
      create(:cms_column_multiple_attachments_upload, cur_form: required_form, order: 1, required: 'required')
    end
    let!(:node) { create :article_node_page, cur_site: site }

    it "is invalid when file_ids is blank on a required column" do
      article_page = build(
        :article_page, cur_site: site, cur_node: node, form: required_form,
        column_values: [
          required_column.value_type.new(column: required_column, file_ids: [])
        ]
      )
      expect(article_page).not_to be_valid
      expect(article_page.column_values.first.errors[:file_ids]).to include(I18n.t("errors.messages.blank"))
    end

    it "accepts non-image files (no only_image_file restriction)" do
      pdf = tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
      article_page = build(
        :article_page, cur_site: site, cur_node: node, form: required_form,
        column_values: [
          required_column.value_type.new(column: required_column, file_ids: [pdf.id.to_s])
        ]
      )
      expect(article_page).to be_valid
    end
  end
end
