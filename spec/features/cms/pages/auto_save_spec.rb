require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let(:name) { unique_id }

  let(:node) { create :cms_node_page, cur_site: site, group_ids: [cms_group.id] }
  let(:item) { create :cms_page, cur_site: site, cur_node: node, html: html }
  let(:html) { "<p>#{unique_id}</p>" }
  let(:page_index_path) { cms_pages_path site.id }
  let(:page_new_path) { new_cms_page_path site.id }
  let(:page_edit_path) { edit_cms_page_path site.id, item }
  let(:page_show_path) { cms_page_path site.id, item }

  before { login_cms_user }

  context "固定ページ(フォルダー直下) 標準" do
    it "new" do
      visit page_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "base_sample"
     end
      within "#addon-cms-agents-addons-file" do
        wait_cbox_open do
          click_on I18n.t("cms.file")
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        wait_cbox_close do
          click_button I18n.t("ss.buttons.attach")
        end
      end
      click_on I18n.t("ss.links.back_to_index")

      visit page_index_path
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.new")
      end
      wait_for_form_restored

      within "form#item-form" do
        within '#selected-files' do
          expect(page).to have_css('.name', text: 'keyvisual.jpg')
        end
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(page).to have_content("sample")
      expect(page).to have_content('keyvisual')
      expect(Cms::Page.count).to eq 1
      Cms::Page.all.first do |plan|
        expect(plan.name).to eq "sample"
        expect(plan.basename).to eq "base_sample.html"
      end
    end

    it "edit" do
      visit page_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
        fill_in "item[index_name]", with: "一覧用タイトル"
     end
      within "#addon-cms-agents-addons-file" do
        wait_cbox_open do
          click_on I18n.t("cms.file")
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        wait_cbox_close do
          click_button I18n.t("ss.buttons.attach")
        end
      end
      click_on I18n.t("ss.links.back_to_show")
      wait_for_js_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      visit page_show_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_form_restored

      within "form#item-form" do
        within '#selected-files' do
          expect(page).to have_css('.name', text: 'keyvisual.jpg')
        end
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("サンプルタイトル")
      expect(Cms::Page.count).to eq 1
      Cms::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
        expect(plan.index_name).to eq "一覧用タイトル"
      end
    end
  end

  context "固定ページ(フォルダー直下) 定型フォーム" do
    before do
      node.st_form_ids = [form.id]
      node.save!
    end
    let!(:column1) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 8, file_type: "image")
    end
    it "new" do
      visit page_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "base_name"
        wait_event_to_fire("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form.name, from: 'in_form_id'
          end
        end
        within ".column-value-cms-column-fileupload" do
          fill_in "item[column_values][][in_wrap][file_label]", with: "keyvisual"
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        wait_cbox_close do
          click_button I18n.t("ss.buttons.attach")
        end
      end
      click_on I18n.t("ss.links.back_to_index")

      visit page_index_path
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.new")
      end
      wait_for_form_restored

      within "form#item-form" do
        expect(page).to have_content('keyvisual.jpg')
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("sample")
      expect(page).to have_content('keyvisual')
      expect(page).to have_content(form.name)
      expect(Cms::Page.count).to eq 1
      Cms::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
        expect(plan.index_name).to eq "一覧用タイトル"
        expect(plan.form_id).to eq form.name
      end
    end

    it "edit" do
      visit page_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
        wait_event_to_fire("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form.name, from: 'in_form_id'
          end
        end
        within ".column-value-cms-column-fileupload" do
          fill_in "item[column_values][][in_wrap][file_label]", with: "keyvisual"
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        wait_cbox_close do
          click_button I18n.t("ss.buttons.attach")
        end
      end
      click_on I18n.t("ss.links.back_to_show")
      wait_for_js_ready
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      visit page_show_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_form_restored

      within "form#item-form" do
        expect(page).to have_content('keyvisual.jpg')
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("サンプルタイトル")
      expect(page).to have_content('keyvisual.jpg')
      expect(page).to have_content(form.name)
      expect(Cms::Page.count).to eq 1
      Cms::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
        expect(plan.index_name).to eq "一覧用タイトル"
        expect(plan.form_id).to eq form.name
      end
    end
  end
end
