require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site, group_ids: [cms_group.id] }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }

  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
  end
  let(:name) { unique_id }
  let(:column1_value) { unique_id }
  let(:html) { "<p>#{unique_id}</p>" }

  before do
    node.st_form_ids = [form.id]
    node.save!
  end

  context 'basic crud with form' do
    before { login_cms_user }

    it do
      visit new_article_page_path(site: site, cid: node)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      # create default form page
      within 'form#item-form' do
        fill_in 'item[name]', with: name
      end
      ensure_addon_opened("#addon-cms-agents-addons-body")
      within "#addon-cms-agents-addons-body" do
        fill_in_ckeditor "item[html]", with: html
      end
      ensure_addon_opened("#addon-cms-agents-addons-file")
      ss_upload_file "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
      within "#addon-cms-agents-addons-file" do
        within '#selected-files' do
          expect(page).to have_css('.name', text: 'keyvisual.gif')
        end
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.draft_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      expect(page).to have_css("#addon-cms-agents-addons-body")
      within "#addon-cms-agents-addons-file" do
        within '#selected-files' do
          expect(page).to have_css('.name', text: 'keyvisual.gif')
        end
      end

      # switch entry form
      click_on I18n.t("ss.links.edit")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      within 'form#item-form' do
        fill_in 'item[name]', with: name
        wait_for_event_fired("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form.name, from: 'in_form_id'
          end
        end
        within ".column-value-cms-column-textfield" do
          fill_in "item[column_values][][in_wrap][value]", with: column1_value
        end
        click_on I18n.t('ss.buttons.draft_save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#addon-cms-agents-addons-form-page .addon-head", text: form.name)
      expect(page).to have_css(".column-value-cms-column-textfield", text: column1_value)
      expect(page).to have_no_css("#addon-cms-agents-addons-body")
      expect(page).to have_no_css("#addon-cms-agents-addons-file")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
    end
  end
end
