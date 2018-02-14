require 'spec_helper'

describe 'article_pages', dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public') }
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
          fill_in "item[column_values][#{column1.id}]", with: column1_value
          click_on I18n.t('ss.buttons.publish_save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Article::Page.all.count).to eq 1

        visit article_pages_path(site: site, cid: node)
        click_on name
        click_on I18n.t('ss.links.copy')

        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Article::Page.all.count).to eq 2

        visit article_pages_path(site: site, cid: node)
        click_on "[#{I18n.t('workflow.cloned_name_prefix')}] #{name}"
        expect(page).to have_content(column1_value)
      end
    end

    context 'with file upload' do
      let!(:column2) { create(:cms_column_file_upload, cur_site: site, cur_form: form) }

      it do
        visit new_article_page_path(site: site, cid: node, form_id: form.id)

        within 'form#item-form' do
          fill_in 'item[name]', with: name
          fill_in "item[column_values][#{column1.id}]", with: column1_value
          find("a[data-column-id=\"#{column2.id}\"]").click
        end

        within 'div#cboxLoadedContent form.user-file' do
          attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/logo.png"
          click_on I18n.t('ss.buttons.save')
        end

        within 'form#item-form' do
          expect(page).to have_content('logo')
          click_on I18n.t('ss.buttons.publish_save')
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
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
        click_on I18n.t('ss.links.copy')

        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
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
