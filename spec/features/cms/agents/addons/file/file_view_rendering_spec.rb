require 'spec_helper'

# 既定フィールドの詳細画面テスト
describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user }
  let!(:file) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: "#{unique_id}.jpg" }
  let(:button_label) { I18n.t("ss.buttons.upload") }
  let(:logo_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let(:keyvisual_path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }

  before do
    login_cms_user
  end

  def upload_file_and_select(file_path)
    within "#item-form #addon-cms-agents-addons-file" do
      wait_for_cbox_opened { click_on button_label }
    end

    within "#ajax-box" do
      page.execute_script("SS_AjaxFile.firesEvents = true;")
      attach_file "item[in_files][]", file_path
      click_button I18n.t("ss.buttons.save")
      expect(page).to have_css('.file-view', text: File.basename(file_path))

      wait_for_cbox_closed do
        wait_for_event_fired "ss:ajaxFileSelected", selector: "#addon-cms-agents-addons-file .ajax-box" do
          click_on File.basename(file_path)
        end
      end
    end
  end

  context "with article/page" do
    describe "index" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"

        upload_file_and_select(logo_path)
        upload_file_and_select(keyvisual_path)

        within ".file-view", text: 'keyvisual.jpg' do
          find(".action-paste").click
        end

        click_on I18n.t("ss.buttons.publish_save")
        click_on I18n.t("ss.buttons.ignore_alert")

        within '#selected-files' do
          expect(page).to have_css(".file-view", text: 'keyvisual.jpg')
          element = find('.file-view', text: 'keyvisual.jpg', match: :first)
          expect(element['class']).not_to include('unused')
          expect(page).to have_css(".file-view.unused", text: 'logo.png')
          element = find('.file-view', text: 'logo.png', match: :first)
          expect(element['class']).to include('unused')
        end
      end

      it "should display deletion button for unused file and delete it successfully" do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"

        upload_file_and_select(logo_path)
        upload_file_and_select(keyvisual_path)

        within ".file-view", text: 'keyvisual.jpg' do
          find(".action-paste").click
        end

        click_on I18n.t("ss.buttons.publish_save")
        click_on I18n.t("ss.buttons.ignore_alert")

        within '#selected-files' do
          within ".file-view.unused" do
            expect(page).to have_content(I18n.t("ss.unused_file"))
            expect(page).to have_content(I18n.t("ss.buttons.delete"))
            click_link I18n.t("ss.buttons.delete")
          end
        end

        wait_for_cbox_opened do
          page.execute_script("SS_AjaxFile.firesEvents = true;")
          within 'form#ajax-form' do
            within "footer.send" do
              click_on I18n.t("ss.buttons.delete")
            end
          end
        end

        within '#selected-files' do
          expect(page).not_to have_css(".file-view.unused", text: 'logo.png')
        end
      end
    end
  end

  context "with cms/file" do
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: "cms/file", user: cms_user, site: site, basename: filename,
        contents: logo_path
      )
    end
    let(:button_label) { I18n.t("cms.file") }
  end
end

# 自由入力の詳細画面テスト
describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) do
    create :article_node_page, cur_site: site, cur_user: cms_user, filename: "docs", name: "article", group_ids: [cms_group.id],
    st_form_ids: [form.id]
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path site.id, node, item }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column1) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", file_type: "video", order: 1)
  end
  let!(:column2) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 2) }
  let!(:file) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: "#{unique_id}.jpg" }
  let(:button_label) { I18n.t("ss.buttons.upload") }
  let(:logo_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  before do
    login_cms_user
    visit edit_path
  end

  it "allows file uploads in form" do
    within 'form#item-form' do
      wait_for_event_fired("ss:formActivated") do
        page.accept_confirm(I18n.t("cms.confirm.change_form")) do
          select form.name, from: 'in_form_id'
        end
      end
    end

    within ".column-value-palette" do
      wait_for_event_fired("ss:columnAdded") do
        click_on column2.name
      end
    end
    within ".column-value-cms-column-free" do
      wait_for_cbox_opened do
        click_on button_label
      end
    end

    within_cbox do
      attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
      click_button I18n.t("ss.buttons.save")
      expect(page).to have_css('.file-view', text: 'shirasagi.pdf')
      click_on 'shirasagi.pdf'

      wait_for_cbox_closed do
        click_on I18n.t('ss.buttons.save')
      end
    end

    within ".column-value-cms-column-free" do
      wait_for_cbox_opened do
        click_on button_label
      end
    end

    within_cbox do
      attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
      click_button I18n.t("ss.buttons.save")
      expect(page).to have_css('.file-view', text: 'logo.png')
      click_on 'logo.png'

      wait_for_cbox_closed do
        click_on I18n.t('ss.buttons.save')
      end
    end

    within "form#item-form" do
      within ".column-value-cms-column-free" do
        within '.column-value-files' do
          expect(page).to have_css('.file-view', text: 'shirasagi.pdf')
          expect(page).to have_css('.file-view', text: 'logo.png')

          within ".file-view", text: 'logo.png' do
            within ".action" do
              find(".btn-file-image-paste").click
            end
          end
        end
      end

      wait_for_js_ready
      click_on I18n.t("ss.buttons.publish_save")
    end

    click_on I18n.t("ss.buttons.ignore_alert")
    wait_for_notice I18n.t('ss.notice.saved')

    within '#addon-cms-agents-addons-form-page' do
      within ".column-value-cms-column-free" do
        within '#selected-files' do
          expect(page).to have_css(".file-view", text: 'logo.png')
          element = find('.file-view', text: 'logo.png', match: :first)
          expect(element['class']).not_to include('unused')
          expect(page).to have_css(".file-view.unused", text: 'shirasagi.pdf')
          element = find('.file-view', text: 'shirasagi.pdf', match: :first)
          expect(element['class']).to include('unused')
          expect(page).to have_content(I18n.t("ss.unused_file"))

          within ".file-view.unused" do
            expect(page).to have_link(I18n.t("ss.buttons.delete"))
          end
        end
      end
    end

    within '#selected-files' do
      within ".file-view.unused" do
        expect(page).to have_link(I18n.t("ss.buttons.delete"))
        click_link I18n.t("ss.buttons.delete")
      end
    end

    within 'form#ajax-form' do
      within "footer.send" do
        click_on I18n.t("ss.buttons.delete")
      end
    end

    within '#selected-files' do
      expect(page).not_to have_css(".file-view.unused", text: 'shirasagi.pdf')
    end
  end

  context "with cms/file" do
    let(:filename) { "#{unique_id}.jpg" }
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: "cms/file", user: cms_user, site: site, basename: filename,
        contents: logo_path
      )
    end
    let(:button_label) { I18n.t("ss.buttons.upload") }
  end
end
