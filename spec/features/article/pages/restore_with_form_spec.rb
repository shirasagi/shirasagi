require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, order: 1, input_type: 'text')
  end
  let!(:column2) do
    create(:cms_column_date_field, cur_site: site, cur_form: form, order: 2)
  end
  let!(:column3) do
    create(:cms_column_url_field, cur_site: site, cur_form: form, order: 3, html_tag: '')
  end
  let!(:column4) do
    create(:cms_column_text_area, cur_site: site, cur_form: form, order: 4)
  end
  let!(:column5) do
    create(:cms_column_select, cur_site: site, cur_form: form, order: 5)
  end
  let!(:column6) do
    create(:cms_column_radio_button, cur_site: site, cur_form: form, order: 6)
  end
  let!(:column7) do
    create(:cms_column_check_box, cur_site: site, cur_form: form, order: 7)
  end
  let!(:column8) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 8, file_type: "image")
  end
  let(:name) { unique_id }
  let(:column1_value) { unique_id }
  let(:column2_value) { "#{rand(2000..2050)}/01/01" }
  let(:column3_value) { "http://#{unique_id}.example.jp/#{unique_id}/" }
  let(:column4_value) { "#{unique_id}#{unique_id}\n#{unique_id}#{unique_id}#{unique_id}" }
  let(:column5_value) { column5.select_options.sample }
  let(:column6_value) { column6.select_options.sample }
  let(:column7_value) { column7.select_options.sample }
  let(:column8_image_text) { unique_id }
  let(:column1_value2) { unique_id }
  let(:column2_value2) { "#{rand(2000..2050)}/01/01" }
  let(:column3_value2) { "http://#{unique_id}.example.jp/#{unique_id}/" }
  let(:column4_value2) { "#{unique_id}#{unique_id}\n#{unique_id}#{unique_id}#{unique_id}" }
  let(:column5_value2) { column5.select_options.sample }
  let(:column6_value2) { column6.select_options.sample }
  let(:column7_value2) { column7.select_options.sample }
  let(:column8_image_text2) { unique_id }

  before do
    node.st_form_ids = [ form.id ]
    node.save!
  end

  context 'restore with form' do
    before { login_cms_user }

    it do
      # Create
      visit new_article_page_path(site: site, cid: node)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        wait_event_to_fire("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form.name, from: 'in_form_id'
          end
        end

        expect(page).to have_css("#addon-cms-agents-addons-form-page .addon-head", text: form.name)

        within ".column-value-cms-column-textfield" do
          fill_in "item[column_values][][in_wrap][value]", with: column1_value
        end
        within ".column-value-cms-column-datefield" do
          fill_in "item[column_values][][in_wrap][date]", with: column2_value
        end
        within ".column-value-cms-column-urlfield" do
          fill_in "item[column_values][][in_wrap][value]", with: column3_value
        end
        within ".column-value-cms-column-textarea" do
          fill_in "item[column_values][][in_wrap][value]", with: column4_value
        end
        within ".column-value-cms-column-select" do
          select column5_value, from: "item[column_values][][in_wrap][value]"
        end
        within ".column-value-cms-column-radiobutton" do
          first(:field, type: "radio", with: column6_value).click
        end
        within ".column-value-cms-column-checkbox" do
          first(:field, name: "item[column_values][][in_wrap][values][]", with: column7_value).click
        end
        within ".column-value-cms-column-fileupload" do
          fill_in "item[column_values][][in_wrap][file_label]", with: column8_image_text
          wait_cbox_open do
            click_on I18n.t("ss.links.upload")
          end
        end
      end
      wait_for_cbox do
        attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/logo.png"
        wait_cbox_close do
          click_on I18n.t('ss.buttons.attach')
        end
      end
      within 'form#item-form' do
        within ".column-value-cms-column-fileupload" do
          expect(page).to have_content("logo.png")
        end
        click_on I18n.t('ss.buttons.draft_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      expect(Article::Page.all.count).to eq 1
      expect(SS::File.all.unscoped.count).to eq 1

      # Update
      visit article_pages_path(site: site, cid: node)
      click_on name
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        within ".column-value-cms-column-textfield" do
          fill_in "item[column_values][][in_wrap][value]", with: column1_value2
        end
        within ".column-value-cms-column-datefield" do
          fill_in "item[column_values][][in_wrap][date]", with: column2_value2
        end
        within ".column-value-cms-column-urlfield" do
          fill_in "item[column_values][][in_wrap][value]", with: column3_value2
        end
        within ".column-value-cms-column-textarea" do
          fill_in "item[column_values][][in_wrap][value]", with: column4_value2
        end
        within ".column-value-cms-column-select" do
          select column5_value2, from: "item[column_values][][in_wrap][value]"
        end
        within ".column-value-cms-column-radiobutton" do
          first(:field, type: "radio", with: column6_value2).click
        end
        within ".column-value-cms-column-checkbox" do
          first(:field, name: "item[column_values][][in_wrap][values][]", with: column7_value).click
          first(:field, name: "item[column_values][][in_wrap][values][]", with: column7_value2).click
        end
        within ".column-value-cms-column-fileupload" do
          fill_in "item[column_values][][in_wrap][file_label]", with: column8_image_text2
          wait_cbox_open do
            click_on I18n.t("ss.links.upload")
          end
        end
      end
      wait_for_cbox do
        attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        wait_cbox_close do
          click_on I18n.t('ss.buttons.attach')
        end
      end
      within 'form#item-form' do
        within ".column-value-cms-column-fileupload" do
          expect(page).to have_content("keyvisual.gif")
        end
        click_on I18n.t('ss.buttons.draft_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      expect(Article::Page.all.count).to eq 1
      expect(SS::File.all.unscoped.count).to eq 1

      # Restore
      visit article_pages_path(site: site, cid: node)
      click_on name
      within '#addon-history-agents-addons-backup' do
        # find('a:last').click
        all('a').last.click
      end

      click_on I18n.t('history.restore')

      within 'form' do
        click_on I18n.t('history.buttons.restore')
      end
      expect(page).to have_css('#notice', text: I18n.t('history.notice.restored'))

      expect(Article::Page.all.count).to eq 1
      Article::Page.all.first.tap do |item|
        expect(item.name).to eq name
        expect(item.column_values.find_by(column_id: column1.id).value).to eq column1_value
        expect(item.column_values.find_by(column_id: column2.id).date).to eq Time.zone.parse(column2_value)
        expect(item.column_values.find_by(column_id: column3.id).value).to eq column3_value
        expect(item.column_values.find_by(column_id: column4.id).value).to eq column4_value.gsub("\n", "\r\n")
        expect(item.column_values.find_by(column_id: column5.id).value).to eq column5_value
        expect(item.column_values.find_by(column_id: column6.id).value).to eq column6_value
        expect(item.column_values.find_by(column_id: column7.id).values).to eq [ column7_value ]
        expect(item.column_values.find_by(column_id: column8.id).file_id).to be_truthy
        expect(item.column_values.find_by(column_id: column8.id).file).to be_truthy
        expect(item.column_values.find_by(column_id: column8.id).file.name).to eq 'logo.png'
        expect(item.column_values.find_by(column_id: column8.id).file_label).to eq column8_image_text
        expect(item.backups.count).to eq 2
      end
      expect(SS::File.all.unscoped.count).to eq 2
    end
  end
end
