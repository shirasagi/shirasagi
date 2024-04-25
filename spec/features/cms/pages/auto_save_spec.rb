require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:name) { unique_id }
  let(:basename) { unique_id }
  let(:index_name) { unique_id }

  let(:node) { create :cms_node_page, cur_site: site, group_ids: [cms_group.id] }
  let(:item) { create :cms_page, cur_site: site, cur_node: node, html: html }
  let(:html) { "<p>#{unique_id}</p>" }
  let(:page_index_path) { cms_pages_path site.id }
  let(:page_new_path) { new_cms_page_path site.id }
  let(:page_edit_path) { edit_cms_page_path site.id, item }
  let(:page_show_path) { cms_page_path site.id, item }

  before { login_cms_user }

  context "auto save without form (with standard body)" do
    context "new" do
      it do
        visit page_new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[basename]", with: basename
        end
        within "#addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("cms.file")
          end
        end
        within_cbox do
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

        expect(page).to have_content(name)
        expect(page).to have_content('keyvisual')
        expect(Cms::Page.count).to eq 1
        Cms::Page.all.first.tap do |cms_page|
          expect(cms_page.name).to eq name
          expect(cms_page.basename).to eq "#{basename}.html"
          expect(cms_page.file_ids.length).to eq 1
          expect(cms_page.files.first.name).to eq 'keyvisual.jpg'
        end
      end
    end

    context "edit" do
      it do
        visit page_edit_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[index_name]", with: index_name
        end
        within "#addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("cms.file")
          end
        end
        within_cbox do
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
        expect(page).to have_content(name)
        expect(Cms::Page.count).to eq 1
        Cms::Page.all.first.tap do |cms_page|
          expect(cms_page.name).to eq name
          expect(cms_page.index_name).to eq index_name
          expect(cms_page.file_ids.length).to eq 1
          expect(cms_page.files.first.name).to eq 'keyvisual.jpg'
        end
      end
    end
  end

  context "固定ページ(フォルダー直下) 定型フォーム" do
    let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
    let!(:column1) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 8, file_type: "image")
    end

    before do
      node.st_form_ids = [form.id]
      node.save!
    end

    context "new" do
      it do
        visit page_new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[basename]", with: basename
          wait_event_to_fire("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
          within ".column-value-cms-column-fileupload" do
            fill_in "item[column_values][][in_wrap][file_label]", with: "keyvisual"
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within_cbox do
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
        expect(page).to have_content(name)
        expect(page).to have_content('keyvisual')
        expect(page).to have_content(form.name)
        expect(Cms::Page.count).to eq 1
        Cms::Page.all.first.tap do |cms_page|
          expect(cms_page.name).to eq name
          expect(cms_page.basename).to eq "#{basename}.html"
          expect(cms_page.form_id).to eq form.id
          expect(cms_page.column_values.count).to eq 1
          cms_page.column_values.first.tap do |column_value|
            expect(column_value).to be_a(Cms::Column::Value::FileUpload)
            expect(column_value.file.name).to eq 'keyvisual.jpg'
          end
        end
      end
    end

    context "edit" do
      it do
        visit page_edit_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          wait_event_to_fire("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end
          within ".column-value-cms-column-fileupload" do
            fill_in "item[column_values][][in_wrap][file_label]", with: "keyvisual"
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within_cbox do
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
        expect(page).to have_content(name)
        expect(page).to have_content('keyvisual.jpg')
        expect(page).to have_content(form.name)
        expect(Cms::Page.count).to eq 1
        Cms::Page.all.first.tap do |cms_page|
          expect(cms_page.name).to eq name
          expect(cms_page.form_id).to eq form.id
          expect(cms_page.column_values.count).to eq 1
          cms_page.column_values.first.tap do |column_value|
            expect(column_value).to be_a(Cms::Column::Value::FileUpload)
            expect(column_value.file.name).to eq 'keyvisual.jpg'
          end
        end
      end
    end
  end
end
