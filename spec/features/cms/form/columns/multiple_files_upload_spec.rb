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

  context 'public page rendering with multiple images' do
    let(:layout) { create_cms_layout }
    let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
    let!(:public_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:column) { create(:cms_column_multiple_files_upload, cur_form: public_form, order: 1) }
    let!(:image1) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let!(:image2) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/webapi/replace.png",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let!(:article_page) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, form: public_form,
        state: 'public',
        column_values: [
          column.value_type.new(
            column: column,
            file_ids: [image1.id.to_s, image2.id.to_s],
            file_labels: {
              image1.id.to_s => "first-image-alt",
              image2.id.to_s => "second-image-alt"
            }
          )
        ]
      )
    end

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "clones both images and renders them in the specified order" do
      article_page.reload
      cloned_ids = article_page.column_values.first.file_ids
      expect(cloned_ids.length).to eq 2
      expect(cloned_ids).not_to include(image1.id.to_s, image2.id.to_s)

      visit article_page.full_url
      expect(page).to have_css("img[alt='first-image-alt']")
      expect(page).to have_css("img[alt='second-image-alt']")
      cloned_ids.each do |cid|
        expect(page).to have_css("img[src*='/fs/#{cid.to_s.chars.join('/')}/']")
      end
      # 元ファイル id への参照が公開画面に流出していないこと
      expect(page).to have_no_css("img[src*='/fs/#{image1.id.to_s.chars.join('/')}/']")
      expect(page).to have_no_css("img[src*='/fs/#{image2.id.to_s.chars.join('/')}/']")
      # 指定順が公開画面 HTML でも維持されること
      expect(page.body.index("first-image-alt")).to be < page.body.index("second-image-alt")
    end
  end

  context 'replacing attached image and editing alt text' do
    let(:layout) { create_cms_layout }
    let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
    let!(:public_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:column) { create(:cms_column_multiple_files_upload, cur_form: public_form, order: 1) }
    let!(:image_before) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let!(:image_after) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/webapi/replace.png",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let!(:article_page) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, form: public_form,
        state: 'public',
        column_values: [
          column.value_type.new(
            column: column,
            file_ids: [image_before.id.to_s],
            file_labels: { image_before.id.to_s => "before-alt" }
          )
        ]
      )
    end

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    # 添付済みの画像を削除 → 新しい画像を追加する操作を再現
    it "reflects the newly attached image on the public page after deletion and re-attachment" do
      article_page.reload
      previous_cloned_id = article_page.column_values.first.file_ids.first

      value = article_page.column_values.first
      value.file_ids = [image_after.id.to_s]
      value.file_labels = { image_after.id.to_s => "after-alt" }
      article_page.save!
      article_page.reload

      new_cloned_id = article_page.column_values.first.file_ids.first
      expect(new_cloned_id).not_to eq previous_cloned_id
      expect(new_cloned_id).not_to eq image_after.id.to_s
      # 置き換え前のクローンは DB から削除されている
      expect(SS::File.where(id: previous_cloned_id).exists?).to be_falsey

      visit article_page.full_url
      expect(page).to have_css("img[src*='/fs/#{new_cloned_id.to_s.chars.join('/')}/']")
      # 置き換え前のクローン画像への参照は公開画面に残っていない
      expect(page).to have_no_css("img[src*='/fs/#{previous_cloned_id.to_s.chars.join('/')}/']")
    end

    # 代替テキスト入力 → alt 属性に反映
    it "uses the entered alt text as the img alt attribute on the public page" do
      article_page.reload

      value = article_page.column_values.first
      current_file_id = value.file_ids.first
      value.file_labels = { current_file_id => "entered-alt-text" }
      article_page.save!
      article_page.reload

      visit article_page.full_url
      expect(page).to have_css("img[alt='entered-alt-text']")
      # 変更前のラベルは公開画面に残っていない
      expect(page).to have_no_css("img[alt='before-alt']")
    end
  end

  context 'public page rendering with multiple PDFs' do
    let(:layout) { create_cms_layout }
    let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
    let!(:pdf_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:pdf_column) { create(:cms_column_multiple_files_upload, cur_form: pdf_form, order: 1) }
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
        contents: "#{Rails.root}/spec/fixtures/opendata/resource.pdf",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let!(:article_page) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, form: pdf_form,
        state: 'public',
        column_values: [
          pdf_column.value_type.new(
            column: pdf_column,
            file_ids: [pdf1.id.to_s, pdf2.id.to_s],
            file_labels: {
              pdf1.id.to_s => "first-pdf-label",
              pdf2.id.to_s => "second-pdf-label"
            }
          )
        ]
      )
    end

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "clones both PDFs and renders them as links in the specified order" do
      article_page.reload
      cloned_ids = article_page.column_values.first.file_ids
      expect(cloned_ids.length).to eq 2
      expect(cloned_ids).not_to include(pdf1.id.to_s, pdf2.id.to_s)

      visit article_page.full_url
      expect(page).to have_css("a", text: "first-pdf-label")
      expect(page).to have_css("a", text: "second-pdf-label")
      cloned_ids.each do |cid|
        expect(page).to have_css("a[href*='/fs/#{cid.to_s.chars.join('/')}/']")
      end
      # 指定順が公開画面 HTML でも維持されること
      expect(page.body.index("first-pdf-label")).to be < page.body.index("second-pdf-label")
    end
  end

  context 'validation errors' do
    let!(:required_form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:required_column) do
      create(:cms_column_multiple_files_upload, cur_form: required_form, order: 1, required: 'required')
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

    it "drops a non-existent file id from file_ids on save without raising" do
      fake_id = BSON::ObjectId.new.to_s
      valid_file = tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
      article_page = create(
        :article_page, cur_site: site, cur_node: node, form: required_form,
        column_values: [
          required_column.value_type.new(column: required_column, file_ids: [fake_id, valid_file.id.to_s])
        ]
      )

      article_page.reload
      saved_ids = article_page.column_values.first.file_ids
      expect(saved_ids).not_to include(fake_id)
      expect(saved_ids.length).to eq 1
    end
  end
end
