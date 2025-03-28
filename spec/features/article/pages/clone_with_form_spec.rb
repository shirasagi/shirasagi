require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: 'text')
  end
  let(:name) { unique_id }
  let(:column1_value) { unique_id }

  before do
    node.st_form_ids = [ form.id ]
    node.save!
  end

  context 'clone formed page' do
    before { login_cms_user }

    context 'with text field' do
      it do
        visit new_article_page_path(site: site, cid: node, form_id: form.id)

        within 'form#item-form' do
          fill_in 'item[name]', with: name
          fill_in "item[column_values][][in_wrap][value]", with: column1_value
          click_on I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(Article::Page.all.count).to eq 1
        page1 = Article::Page.all.first
        expect(page1.first_released).to be_present

        visit article_pages_path(site: site, cid: node)
        click_on name
        click_on I18n.t('ss.links.copy')

        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(Article::Page.all.count).to eq 2

        page2 = Article::Page.all.ne(id: page1.id).first
        expect(page2.name).to eq "[#{I18n.t('workflow.cloned_name_prefix')}] #{name}"
        expect(page2.first_released).to be_blank

        visit article_pages_path(site: site, cid: node)
        click_on "[#{I18n.t('workflow.cloned_name_prefix')}] #{name}"
        expect(page).to have_content(column1_value)
      end
    end

    context 'with file upload' do
      let!(:column2) { create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: "attachment") }

      it do
        visit new_article_page_path(site: site, cid: node, form_id: form.id)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within 'form#item-form' do
          fill_in 'item[name]', with: name
          fill_in "item[column_values][][in_wrap][value]", with: column1_value
          # find("a[data-column-id=\"#{column2.id}\"]").click
          within first(".column-value-cms-column-fileupload") do
            fill_in "item[column_values][][in_wrap][file_label]", with: unique_id
            # wait_for_cbox_opened { click_on I18n.t("ss.links.upload") }
          end

          ss_upload_file "#{Rails.root}/spec/fixtures/ss/logo.png", addon: ".column-value-cms-column-fileupload"

          expect(page).to have_css('.file-view', text: 'logo')
          click_on I18n.t('ss.buttons.publish_save')
        end

        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(Article::Page.all.count).to eq 1
        Article::Page.all.find_by(name: name).tap do |item|
          expect(item.column_values.length).to eq 2
          item.column_values.where(column_id: column2.id).first.tap do |column_value|
            expect(column_value.file_id).not_to be_nil
            @source_file_id = column_value.file_id
          end
        end

        visit article_pages_path(site: site, cid: node)
        click_on name
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t('ss.links.copy')

        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(Article::Page.all.count).to eq 2

        visit article_pages_path(site: site, cid: node)
        click_on "[#{I18n.t('workflow.cloned_name_prefix')}] #{name}"
        expect(page).to have_content(column1_value)

        Article::Page.all.find_by(name: "[#{I18n.t('workflow.cloned_name_prefix')}] #{name}").tap do |item|
          expect(item.column_values.length).to eq 2
          item.column_values.where(column_id: column2.id).first.tap do |column_value|
            expect(column_value.file_id).not_to be_nil
            # cloned file has individual file id
            expect(column_value.file_id).not_to eq @source_file_id
          end
        end
      end
    end
  end
end
