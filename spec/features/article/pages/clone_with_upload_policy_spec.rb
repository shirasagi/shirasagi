require 'spec_helper'

describe 'article_pages_with_upload_policy', type: :feature, dbscope: :example, js: true do
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

  before { upload_policy_before_settings("sanitizer") }

  after { upload_policy_after_settings }

  context 'clone formed page' do
    before { login_cms_user }

    context 'with file upload' do
      let!(:column2) { create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: "attachment") }

      it do
        visit new_article_page_path(site: site, cid: node, form_id: form.id)

        within 'form#item-form' do
          fill_in 'item[name]', with: name
          fill_in "item[column_values][][in_wrap][value]", with: column1_value
          within first(".column-value-cms-column-fileupload") do
            fill_in "item[column_values][][in_wrap][file_label]", with: unique_id
            wait_for_cbox_opened do
              click_on I18n.t("ss.links.upload")
            end
          end
        end

        within_cbox do
          attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/logo.png"
          wait_for_cbox_closed do
            click_on I18n.t('ss.buttons.attach')
          end
        end

        within 'form#item-form' do
          expect(page).to have_content('logo')
          click_on I18n.t('ss.buttons.publish_save')
        end

        wait_for_notice I18n.t('ss.notice.saved')
        expect(page).to have_css('.file-view .sanitizer-wait')

        # restore
        file = SS::File.first
        restored_file = mock_sanitizer_restore(file)

        # clone
        visit article_pages_path(site: site, cid: node)
        click_on name

        expect(page).to have_css('.file-view .sanitizer-complete')

        click_on I18n.t('ss.links.copy')
        copy_name = "copy #{name}"
        within 'form#item-form' do
          fill_in 'item[name]', with: copy_name
          click_on I18n.t('ss.buttons.save')
        end

        wait_for_notice I18n.t('ss.notice.saved')

        click_on copy_name
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        expect(page).to have_css('.file-view .sanitizer-wait')
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end
  end
end
