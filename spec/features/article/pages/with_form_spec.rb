require 'spec_helper'

describe 'article_pages', dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public') }
  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: 'text')
  end
  let!(:column2) do
    create(:cms_column_date_field, cur_site: site, cur_form: form)
  end
  let!(:column3) do
    create(:cms_column_url_field, cur_site: site, cur_form: form, html_tag: '')
  end
  let!(:column4) do
    create(:cms_column_text_area, cur_site: site, cur_form: form)
  end
  let!(:column5) do
    create(:cms_column_select, cur_site: site, cur_form: form)
  end
  let!(:column6) do
    create(:cms_column_radio_button, cur_site: site, cur_form: form)
  end
  let!(:column7) do
    create(:cms_column_check_box, cur_site: site, cur_form: form)
  end
  let!(:column8) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, html_tag: 'a+img')
  end
  let(:name) { unique_id }
  let(:column1_value) { unique_id }
  let(:column2_value) { "#{rand(2000..2050)}/01/01" }
  let(:column3_value) { "http://#{unique_id}.example.jp/#{unique_id}/" }
  let(:column4_value) { "#{unique_id}#{unique_id}\n#{unique_id}#{unique_id}#{unique_id}" }
  let(:column5_value) { column5.select_options.sample }
  let(:column6_value) { column6.select_options.sample }
  let(:column7_value) { column7.select_options.sample }

  before do
    node.st_form_ids = [ form.id ]
    node.save!
  end

  context 'basic crud with form' do
    before { login_cms_user }

    it do
      visit new_article_page_path(site: site, cid: node)

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        select form.name, from: 'item[form_id]'
        find('.btn-form-change').click

        fill_in "item[column_values][#{column1.id}]", with: column1_value
        fill_in "item[column_values][#{column2.id}]", with: column2_value
        fill_in "item[column_values][#{column3.id}]", with: column3_value
        fill_in "item[column_values][#{column4.id}]", with: column4_value
        select column5_value, from: "item[column_values][#{column5.id}]"
        choose "item_column_values_#{column6.id}_#{column6_value}"
        first(:field, name: "item[column_values][#{column7.id}][]", with: column7_value).click
        find("a[data-column-id=\"#{column8.id}\"]").click
      end
      within 'div#cboxLoadedContent form.user-file' do
        attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_on I18n.t('ss.buttons.save')
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.publish_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
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
        expect(item.column_values.find_by(column_id: column8.id).file.name).to eq 'logo.png'
      end
    end
  end
end
