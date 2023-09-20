require 'spec_helper'

describe "aute_save", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let(:name) { unique_id }

  let(:article_node) { create :article_node_page, cur_site: site, group_ids: [cms_group.id] } # st_form_ids: [form.id]
  let(:article_item) { create :article_page, cur_node: article_node } # group_ids: [cms_group.id]
  let(:article_index_path) { article_pages_path site.id, article_node }
  let(:article_new_path) { new_article_page_path site.id, article_node }
  let(:article_edit_path) { edit_article_page_path site.id, article_node, article_item }
  let(:article_show_path) { article_page_path site.id, article_node, article_item }

  let(:node) { create :cms_node_page, cur_site: site, group_ids: [cms_group.id] }
  let(:item) { create :cms_page, cur_site: site, cur_node: node, html: html }
  let(:html) { "<p>#{unique_id}</p>" }
  let(:page_index_path) { cms_pages_path site.id }
  let(:page_new_path) { new_cms_page_path site.id }
  let(:page_edit_path) { edit_cms_page_path site.id, item }
  let(:page_show_path) { cms_page_path site.id, item }

  let(:node_node) { create :cms_node_page, st_form_ids: [form.id] }
  let(:node_item) { create :cms_page, cur_node: node_node, group_ids: [group.id] }
  let(:node_index_path) { node_pages_path site.id, node_node }
  let(:node_new_path) { new_node_page_path site.id, node_node }
  let(:node_edit_path) { edit_node_page_path site.id, node_node, node_item }
  let(:node_show_path) { node_page_path site.id, node_node, node_item }

  let(:event_node) { create(:event_node_page, group_ids: [group.id]) }
  let(:event_item) { create(:event_page, cur_node: event_node) }
  let(:event_index_path) { event_pages_path site.id, event_node }
  let(:event_new_path) { new_event_page_path site.id, event_node }
  let(:event_edit_path) { edit_event_page_path site.id, event_node, event_item }
  let(:event_show_path) { event_page_path site.id, event_node, event_item }

  let(:faq_node) { create(:faq_node_page, group_ids: [group.id]) }
  let(:faq_item) { create(:faq_page, cur_node: faq_node) }
  let(:faq_index_path) { faq_pages_path site.id, faq_node }
  let(:faq_new_path) { new_faq_page_path site.id, faq_node }
  let(:faq_edit_path) { edit_faq_page_path site.id, faq_node, faq_item }
  let(:faq_show_path) { faq_page_path site.id, faq_node, faq_item }

  before { login_cms_user }

  context "記事ページ 標準" do
    it "new" do
      visit article_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[index_name]", with: "index_sample"
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

      visit article_index_path
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
      expect(Article::Page.count).to eq 1
      Article::Page.all.first do |plan|
        expect(plan.name).to eq "sample"
        expect(plan.index_name).to eq "index_sample"
      end
    end

    it "edit" do
      visit article_edit_path
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

      visit article_show_path
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
      expect(page).to have_content('keyvisual')
      expect(Article::Page.count).to eq 1
      Article::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
        expect(plan.index_name).to eq "一覧用タイトル"
      end
    end
  end

  context "記事ページ 定型フォーム" do
    before do
      article_node.st_form_ids = [form.id]
      article_node.save!
    end
    let!(:column1) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 8, file_type: "image")
    end
    it "new" do
      visit article_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[index_name]", with: "index_sample"
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

      visit article_index_path
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.new")
      end
      wait_for_form_restored

      within "form#item-form" do
        expect(page).to have_content(form.name)
        expect(page).to have_content("keyvisual.jpg")
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(page).to have_content("sample")
      expect(page).to have_content('keyvisual.jpg')
      expect(Article::Page.count).to eq 1
      Article::Page.all.first do |plan|
        expect(plan.name).to eq "sample"
        expect(plan.index_name).to eq "index_sample"
      end
    end

    it "edit" do
      visit article_edit_path
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

      visit article_show_path
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      page.accept_confirm(I18n.t("ss.confirm.resume_editing")) do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_form_restored

      within "form#item-form" do
        expect(page).to have_content(form.name)
        expect(page).to have_content('keyvisual.jpg')
        click_on I18n.t('ss.buttons.publish_save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("サンプルタイトル")
      expect(page).to have_content('keyvisual.jpg')
      expect(Article::Page.count).to eq 1
      Article::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
      end
    end
  end

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

  context "固定ページ(記事フォルダー配下) 標準" do
    it "new" do
      visit node_new_path
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

      visit node_index_path
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
        expect(plan.index_name).to eq "base_sample"
        expect(plan.form_id).to eq form.name
      end
    end

    it "edit" do
      visit node_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
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

      visit node_show_path
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
      expect(page).to have_content('keyvisual')
      expect(Cms::Page.count).to eq 1
      Cms::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
        expect(plan.form_id).to eq form.name
      end
    end
  end

  context "固定ページ(記事フォルダー配下) 定型フォーム" do
    before do
      node_node.st_form_ids = [form.id]
      node_node.save!
    end
    let!(:column1) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 8, file_type: "image")
    end
    it "new" do
      visit node_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
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

      visit node_index_path
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
      expect(page).to have_content('keyvisual.jpg')
      expect(page).to have_content(form.name)
      expect(Cms::Page.count).to eq 1
      Cms::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
        expect(plan.index_name).to eq "一覧用タイトル"
        expect(plan.form_id).to eq form.name
      end
    end

    it "edit" do
      visit node_edit_path
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

      visit node_show_path
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

  context "FAQページ" do
    it "new" do
      visit faq_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
      end
      within "#addon-cms-agents-addons-file" do
        wait_cbox_open do
          click_on I18n.t("ss.buttons.upload")
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        wait_cbox_close do
          click_on I18n.t('ss.buttons.attach')
        end
      end
      click_on I18n.t("ss.links.back_to_index")

      visit faq_index_path
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
      expect(Faq::Page.count).to eq 1
      Faq::Page.all.first do |plan|
        expect(plan.name).to eq "sample"
      end
    end

    it "edit" do
      visit faq_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
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

      visit faq_show_path
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
      expect(page).to have_content('keyvisual')
      expect(Faq::Page.count).to eq 1
      Faq::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
      end
    end
  end

  context "イベントページ" do
    it "new" do
      visit event_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
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

      visit event_index_path
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
      expect(Event::Page.count).to eq 1
      Event::Page.all.first do |plan|
        expect(plan.name).to eq "sample"
      end
    end

    it "edit" do
      visit event_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "サンプルタイトル"
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

      visit event_show_path
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
      expect(page).to have_content('keyvisual')
      expect(Event::Page.count).to eq 1
      Event::Page.all.first do |plan|
        expect(plan.name).to eq "サンプルタイトル"
      end
    end
  end
end