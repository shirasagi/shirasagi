require 'spec_helper'

describe "gws_report_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "public" }
  let!(:column1_text1) do
    create(:gws_column_text_field, cur_site: site, form: form, order: 10, required: "optional", input_type: "text")
  end
  let!(:column1_text2) do
    create(:gws_column_text_field, cur_site: site, form: form, order: 11, required: "optional", input_type: "email")
  end
  let!(:column1_text3) do
    create(:gws_column_text_field, cur_site: site, form: form, order: 12, required: "optional", input_type: "tel")
  end
  let!(:column2_date1) do
    create(:gws_column_date_field, cur_site: site, form: form, order: 20, required: "optional", input_type: "date")
  end
  let!(:column2_date2) do
    create(:gws_column_date_field, cur_site: site, form: form, order: 21, required: "optional", input_type: "datetime")
  end
  let!(:column3) { create(:gws_column_number_field, cur_site: site, form: form, order: 30, required: "optional") }
  let!(:column4) { create(:gws_column_url_field, cur_site: site, form: form, order: 40, required: "optional") }
  let!(:column5) { create(:gws_column_text_area, cur_site: site, form: form, order: 50, required: "optional") }
  let!(:column6) { create(:gws_column_select, cur_site: site, form: form, order: 60, required: "optional") }
  let!(:column7) { create(:gws_column_radio_button, cur_site: site, form: form, order: 70, required: "optional") }
  let!(:column8) { create(:gws_column_check_box, cur_site: site, form: form, order: 80, required: "optional") }
  let!(:column9) { create(:gws_column_file_upload, cur_site: site, form: form, order: 90, required: "optional") }

  context "print" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:column_value1_text1) { unique_id }
    let(:column_value1_text2) { "#{unique_id}@example.jp" }
    let(:column_value1_text3) { Array.new(8) { rand(10).to_s }.join }
    let(:column_value2_date1) { Time.zone.now.change(hour: 0, min: 0, sec: 0) }
    let(:column_value2_date2) { Time.zone.now.change(min: 0, sec: 0) }
    let(:column_value3) { rand(column3.min_decimal.to_i..column3.max_decimal.to_i) }
    let(:column_value4) { "http://#{unique_id}.example.jp" }
    let(:column_value5) { Array.new(rand(2..5)) { unique_id }.join("\n") }
    let(:column_value6) { column6.select_options.sample }
    let(:column_value7) { column7.select_options.sample }
    let(:column_value8) { column8.select_options.sample }

    before do
      login_gws_user

      # Create
      visit gws_report_files_main_path(site: site)
      within "#menu" do
        click_on I18n.t("ss.links.new")
        within ".gws-dropdown-menu" do
          click_on form.name
        end
      end

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "custom[#{column1_text1.id}]", with: column_value1_text1
        fill_in "custom[#{column1_text2.id}]", with: column_value1_text2
        fill_in "custom[#{column1_text3.id}]", with: column_value1_text3
        fill_in "custom[#{column2_date1.id}]", with: column_value2_date1.strftime("%Y/%m/%d")
        fill_in "custom[#{column2_date2.id}]", with: column_value2_date2.strftime("%Y/%m/%d %H:%M")
        fill_in "custom[#{column3.id}]", with: column_value3
        fill_in "custom[#{column4.id}]", with: column_value4
        fill_in "custom[#{column5.id}]", with: column_value5
        select column_value6, from: "custom[#{column6.id}]"
        find("input[name='custom[#{column7.id}]'][value='#{column_value7}']").click
        find("input[name='custom[#{column8.id}][]'][value='#{column_value8}']").click
        wait_cbox_open do
          first(".btn-file-upload").click
        end
      end
      wait_for_ajax do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        wait_cbox_close do
          click_on I18n.t("ss.buttons.attach")
        end
      end
      within "form#item-form" do
        expect(page).to have_css(".column-#{column9.id}", text: "logo")
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it do
      # Copy
      visit gws_report_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('gws/report.options.file_state.closed')
      end
      click_on name
      click_on I18n.t("ss.links.copy")

      within "form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Report::File.all.count).to eq 2
      file = Gws::Report::File.all.site(site).find_by(name: name2)
      expect(file.column_values.count).to eq form.columns.count
      file.column_values.where(column_id: column1_text1.id).first.tap do |cv|
        expect(cv.value).to eq column_value1_text1
      end
      file.column_values.where(column_id: column1_text2.id).first.tap do |cv|
        expect(cv.value).to eq column_value1_text2
      end
      file.column_values.where(column_id: column1_text3.id).first.tap do |cv|
        expect(cv.value).to eq column_value1_text3
      end
      file.column_values.where(column_id: column2_date1.id).first.tap do |cv|
        expect(cv.date).to eq column_value2_date1
      end
      file.column_values.where(column_id: column2_date2.id).first.tap do |cv|
        expect(cv.date).to eq column_value2_date2
      end
      file.column_values.where(column_id: column3.id).first.tap do |cv|
        expect(cv.decimal).to eq BigDecimal(column_value3)
      end
      file.column_values.where(column_id: column4.id).first.tap do |cv|
        expect(cv.value).to eq column_value4
      end
      file.column_values.where(column_id: column5.id).first.tap do |cv|
        expect(cv.value).to eq column_value5.gsub("\n", "\r\n")
      end
      file.column_values.where(column_id: column6.id).first.tap do |cv|
        expect(cv.value).to eq column_value6
      end
      file.column_values.where(column_id: column7.id).first.tap do |cv|
        expect(cv.value).to eq column_value7
      end
      file.column_values.where(column_id: column8.id).first.tap do |cv|
        expect(cv.values).to eq [ column_value8 ]
      end
      file.column_values.where(column_id: column9.id).first.tap do |cv|
        expect(cv.files.count).to eq 1
        cv.files.first.tap do |cv_file|
          expect(cv_file.name).to eq "logo.png"
          expect(cv_file.filename).to eq "logo.png"
          expect(cv_file.site_id).to be_blank
          expect(cv_file.model).to eq "Gws::Report::File"
          expect(cv_file.owner_item_id).to eq file.id
          expect(cv_file.owner_item_type).to eq file.class.name
        end
      end
      expect(file.state).to eq "closed"
      expect(file.deleted).to be_blank
    end
  end
end
