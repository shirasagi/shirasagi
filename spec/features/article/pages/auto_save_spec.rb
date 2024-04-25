require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let(:article_node) { create :article_node_page, cur_site: site, group_ids: [cms_group.id] } # st_form_ids: [form.id]
  let(:article_item) { create :article_page, cur_node: article_node } # group_ids: [cms_group.id]
  let(:article_index_path) { article_pages_path site.id, article_node }
  let(:article_new_path) { new_article_page_path site.id, article_node }
  let(:article_edit_path) { edit_article_page_path site.id, article_node, article_item }
  let(:article_show_path) { article_page_path site.id, article_node, article_item }

  before { login_cms_user }

  context "auto save without form (with standard body)" do
    let(:name) { unique_id }
    let(:index_name) { unique_id }

    context "new" do
      it do
        visit article_new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[index_name]", with: index_name
        end
        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
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

        expect(page).to have_content(index_name)
        expect(page).to have_content('keyvisual')
        expect(Article::Page.count).to eq 1
        Article::Page.all.first.tap do |article_page|
          expect(article_page.name).to eq name
          expect(article_page.index_name).to eq index_name
          expect(article_page.file_ids.length).to eq 1
          expect(article_page.files.first.name).to eq 'keyvisual.jpg'
        end
      end
    end

    context "edit" do
      it do
        visit article_edit_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[index_name]", with: index_name
        end
        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
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

        expect(page).to have_content(name)
        expect(page).to have_content('keyvisual')
        expect(Article::Page.count).to eq 1
        Article::Page.all.first.tap do |article_page|
          expect(article_page.name).to eq name
          expect(article_page.index_name).to eq index_name
          expect(article_page.file_ids.length).to eq 1
          expect(article_page.files.first.name).to eq 'keyvisual.jpg'
        end
      end
    end
  end

  context "auto save with form" do
    let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
    let!(:column1) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 8, file_type: "image")
    end
    let(:name) { unique_id }
    let(:index_name) { unique_id }

    before do
      article_node.st_form_ids = [ form.id ]
      article_node.save!
    end

    context "new" do
      it do
        visit article_new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[index_name]", with: index_name
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
        within_cbox do
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

        expect(page).to have_content(name)
        expect(page).to have_content('keyvisual.jpg')
        expect(Article::Page.count).to eq 1
        Article::Page.all.first.tap do |article_page|
          expect(article_page.name).to eq name
          expect(article_page.index_name).to eq index_name
          expect(article_page.form_id).to eq form.id
          expect(article_page.column_values.count).to eq 1
          article_page.column_values.first.tap do |column_value|
            expect(column_value).to be_a(Cms::Column::Value::FileUpload)
            expect(column_value.file.name).to eq 'keyvisual.jpg'
          end
        end
      end
    end

    context "edit" do
      it do
        visit article_edit_path
        within "form#item-form" do
          fill_in "item[name]", with: name
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
        within_cbox do
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
        expect(page).to have_content(name)
        expect(page).to have_content('keyvisual.jpg')
        expect(Article::Page.count).to eq 1
        Article::Page.all.first.tap do |article_page|
          expect(article_page.name).to eq name
          expect(article_page.form_id).to eq form.id
          expect(article_page.column_values.count).to eq 1
          article_page.column_values.first.tap do |column_value|
            expect(column_value).to be_a(Cms::Column::Value::FileUpload)
            expect(column_value.file.name).to eq 'keyvisual.jpg'
          end
        end
      end
    end
  end
end
