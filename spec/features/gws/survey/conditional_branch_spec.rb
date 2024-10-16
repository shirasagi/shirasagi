require 'spec_helper'

describe "gws_survey", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user1) { create(:gws_user, uid: "u01", group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user2) { create(:gws_user, uid: "u02", group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user3) { create(:gws_user, uid: "u03", group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user4) { create(:gws_user, uid: "u04", group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:due_date) { I18n.l(Time.zone.today + 14, format: :picker) }

  before do
    clear_downloads
  end

  after do
    clear_downloads
  end

  context "conditional branch" do
    let(:form_name) { "form-#{unique_id}" }
    let(:radio_name) { "column-#{unique_id}" }
    let(:radio_option0) { "option-#{unique_id}" }
    let(:radio_option1) { "option-#{unique_id}" }
    let(:radio_option2) { "option-#{unique_id}" }
    let(:radio_other1) { "other-option-#{unique_id}" }
    let(:radio_options) { [ radio_option0, radio_option1, radio_option2 ] }
    let(:section1_name) { "column-#{unique_id}" }
    let(:section1_text_name) { "column-#{unique_id}" }
    let(:section2_name) { "column-#{unique_id}" }
    let(:section2_text_name) { "column-#{unique_id}" }
    let(:section1_text_value) { "text-#{unique_id}" }
    let(:section2_text_value) { "text-#{unique_id}" }

    it do
      login_gws_user

      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end

      within "form#item-form" do
        fill_in "item[name]", with: form_name
        fill_in "item[due_date]", with: due_date
        choose I18n.t("gws.options.readable_setting_range.public")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved") # TODO: timeout
      clear_notice

      expect(Gws::Survey::Form.all.count).to eq 1
      survey_form = Gws::Survey::Form.all.first
      expect(survey_form.name).to eq form_name

      within ".gws-column-list-toolbar[data-placement='bottom']" do
        wait_for_event_fired("gws:column:added") { click_on I18n.t("gws.columns.gws/radio_button") }
      end
      within "form.gws-column-form" do
        fill_in "item[name]", with: radio_name
        fill_in "item[select_options]", with: radio_options.join("\n")
        choose "item_other_state_enabled"
        choose "item_other_required_required"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      clear_notice

      within ".gws-column-list-toolbar[data-placement='bottom']" do
        wait_for_event_fired("gws:column:added") { click_on I18n.t("gws.columns.gws/section") }
      end
      within "form.gws-column-form" do
        fill_in "item[name]", with: section1_name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      clear_notice

      within ".gws-column-list-toolbar[data-placement='bottom']" do
        wait_for_event_fired("gws:column:added") { click_on I18n.t("gws.columns.gws/text_field") }
      end
      within "form.gws-column-form" do
        fill_in "item[name]", with: section1_text_name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      clear_notice

      within ".gws-column-list-toolbar[data-placement='bottom']" do
        wait_for_event_fired("gws:column:added") { click_on I18n.t("gws.columns.gws/section") }
      end
      within "form.gws-column-form" do
        fill_in "item[name]", with: section2_name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      clear_notice

      within ".gws-column-list-toolbar[data-placement='bottom']" do
        wait_for_event_fired("gws:column:added") { click_on I18n.t("gws.columns.gws/text_field") }
      end
      within "form.gws-column-form" do
        fill_in "item[name]", with: section2_text_name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      clear_notice

      survey_form.reload
      radio_column = survey_form.columns.where(name: radio_name).first
      expect(radio_column).to be_present
      within "[data-id='#{radio_column.id}']" do
        wait_for_event_fired("turbo:frame-load") { click_on "format_list_bulleted" }
      end
      within "form.gws-column-form" do
        expect(page).to have_css(".gws-column-form-grid tr", count: radio_options.length + 1)
        within all(".gws-column-form-grid tr")[2] do
          select I18n.t("gws/column.show_section", name: section1_name), from: "item[branch_section_ids][]"
        end
        within all(".gws-column-form-grid tr")[3] do
          select I18n.t("gws/column.show_section", name: section2_name), from: "item[branch_section_ids][]"
        end
        wait_for_event_fired("turbo:frame-load") { click_on I18n.t("ss.buttons.save") }
      end
      wait_for_notice I18n.t("ss.notice.saved")
      clear_notice

      section1_column = survey_form.columns.where(name: section1_name).first
      expect(section1_column).to be_present
      section1_text_column = survey_form.columns.where(name: section1_text_name).first
      expect(section1_text_column).to be_present
      section2_column = survey_form.columns.where(name: section2_name).first
      expect(section2_column).to be_present
      section2_text_column = survey_form.columns.where(name: section2_text_name).first
      expect(section2_text_column).to be_present

      radio_column.reload
      expect(radio_column.name).to eq radio_name
      expect(radio_column.order).to eq 10
      expect(radio_column.required).to eq "required"
      expect(radio_column.tooltips).to be_blank
      expect(radio_column.prefix_label).to be_blank
      expect(radio_column.postfix_label).to be_blank
      expect(radio_column.prefix_explanation).to be_blank
      expect(radio_column.postfix_explanation).to be_blank
      expect(radio_column.select_options).to eq radio_options
      expect(radio_column.branch_section_ids).to have(3).items
      expect(radio_column.branch_section_ids[0]).to be_blank
      expect(radio_column.branch_section_ids[1]).to eq section1_column.id.to_s
      expect(radio_column.branch_section_ids[2]).to eq section2_column.id.to_s

      #
      # 公開する
      #
      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form_name
      click_on I18n.t("gws/workflow.links.publish")

      within "form#item-form" do
        click_on(I18n.t("ss.buttons.save"))
      end
      wait_for_notice I18n.t("ss.notice.published")

      #
      # answer by user1
      #
      login_user user1
      visit gws_survey_main_path(site: site)
      click_on form_name
      wait_for_js_ready

      within "form#item-form" do
        within ".radio-button-#{radio_column.id}" do
          wait_for_event_fired("column:sectionChanged") { choose radio_option0 }
        end

        click_on I18n.t("ss.buttons.answer")
      end
      wait_for_notice I18n.t("ss.notice.answered")

      #
      # answer by user2
      #
      login_user user2
      visit gws_survey_main_path(site: site)
      click_on form_name
      wait_for_js_ready

      within "form#item-form" do
        within ".radio-button-#{radio_column.id}" do
          wait_for_event_fired("column:sectionChanged") { choose radio_option1 }
        end

        click_on I18n.t("ss.buttons.answer")
      end
      message = "#{section1_text_column.name}#{I18n.t("errors.messages.blank")}"
      wait_for_error message

      within "form#item-form" do
        within all(".section-#{section1_column.id}")[1] do
          fill_in "custom[#{section1_text_column.id}]", with: section1_text_value
        end

        click_on I18n.t("ss.buttons.answer")
      end
      wait_for_notice I18n.t("ss.notice.answered")

      #
      # answer by user3
      #
      login_user user3
      visit gws_survey_main_path(site: site)
      click_on form_name
      wait_for_js_ready

      within "form#item-form" do
        within ".radio-button-#{radio_column.id}" do
          wait_for_event_fired("column:sectionChanged") { choose radio_option2 }
        end

        click_on I18n.t("ss.buttons.answer")
      end
      message = "#{section2_text_column.name}#{I18n.t("errors.messages.blank")}"
      wait_for_error message

      within "form#item-form" do
        within all(".section-#{section2_column.id}")[1] do
          fill_in "custom[#{section2_text_column.id}]", with: section2_text_value
        end

        click_on I18n.t("ss.buttons.answer")
      end
      wait_for_notice I18n.t("ss.notice.answered")

      #
      # answer by user4
      #
      login_user user4
      visit gws_survey_main_path(site: site)
      click_on form_name
      wait_for_js_ready

      within "form#item-form" do
        within ".radio-button-#{radio_column.id}" do
          wait_for_event_fired("column:sectionChanged") { choose I18n.t("gws/column.other_value") }
        end
        script = <<~SCRIPT
          document.querySelector("[name='custom[#{radio_column.id}_other_value]']").removeAttribute('required')
        SCRIPT
        page.execute_script(script)
        click_on I18n.t("ss.buttons.answer")
      end
      message = "#{radio_column.name}#{I18n.t("errors.messages.blank")}"
      wait_for_error message

      within "form#item-form" do
        fill_in "custom[#{radio_column.id}_other_value]", with: radio_other1

        click_on I18n.t("ss.buttons.answer")
      end
      wait_for_notice I18n.t("ss.notice.answered")

      Gws::Survey::File.all.reorder(user_id: 1).to_a.tap do |files|
        expect(files.count).to eq 4
        files[0].tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.form_id).to eq survey_form.id
          expect(file.user_id).to eq user1.id
          file.column_values.reorder(column_id: 1).to_a.tap do |column_values|
            expect(column_values).to have(3).items
            column_values[0].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::RadioButton)
              expect(column_value.column_id).to eq radio_column.id
              expect(column_value.value).to eq radio_option0
              expect(column_value.other_value).to be_blank
            end
            column_values[1].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section1_column.id
              expect(column_value.value).to eq section1_column.name
            end
            column_values[2].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section2_column.id
              expect(column_value.value).to eq section2_column.name
            end
          end
        end
        files[1].tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.form_id).to eq survey_form.id
          expect(file.user_id).to eq user2.id
          file.column_values.reorder(column_id: 1).to_a.tap do |column_values|
            expect(column_values).to have(4).items
            column_values[0].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::RadioButton)
              expect(column_value.column_id).to eq radio_column.id
              expect(column_value.value).to eq radio_option1
              expect(column_value.other_value).to be_blank
            end
            column_values[1].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section1_column.id
              expect(column_value.value).to eq section1_column.name
            end
            column_values[2].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section1_text_column.id
              expect(column_value.value).to eq section1_text_value
            end
            column_values[3].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section2_column.id
              expect(column_value.value).to eq section2_column.name
            end
          end
        end
        files[2].tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.form_id).to eq survey_form.id
          expect(file.user_id).to eq user3.id
          file.column_values.reorder(column_id: 1).to_a.tap do |column_values|
            expect(column_values).to have(4).items
            column_values[0].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::RadioButton)
              expect(column_value.column_id).to eq radio_column.id
              expect(column_value.value).to eq radio_option2
              expect(column_value.other_value).to be_blank
            end
            column_values[1].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section1_column.id
              expect(column_value.value).to eq section1_column.name
            end
            column_values[2].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section2_column.id
              expect(column_value.value).to eq section2_column.name
            end
            column_values[3].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section2_text_column.id
              expect(column_value.value).to eq section2_text_value
            end
          end
        end
        files[3].tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.form_id).to eq survey_form.id
          expect(file.user_id).to eq user4.id
          file.column_values.reorder(column_id: 1).to_a.tap do |column_values|
            expect(column_values).to have(3).items
            column_values[0].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::RadioButton)
              expect(column_value.column_id).to eq radio_column.id
              expect(column_value.value).to eq Gws::Column::RadioButton::OTHER_VALUE
              expect(column_value.other_value).to eq radio_other1
            end
            column_values[1].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section1_column.id
              expect(column_value.value).to eq section1_column.name
            end
            column_values[2].tap do |column_value|
              expect(column_value).to be_a(Gws::Column::Value::TextField)
              expect(column_value.column_id).to eq section2_column.id
              expect(column_value.value).to eq section2_column.name
            end
          end
        end
      end

      #
      # 回答一覧
      #
      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form_name
      click_on I18n.t("gws/survey.view_files")

      within ".form-table-body-inner" do
        expect(page).to have_css("tbody tr", count: 4)
        all("tbody tr").tap do |rows|
          within rows[0] do
            expect(page).to have_content user1.long_name
            expect(page).to have_content radio_option0
          end
          within rows[1] do
            expect(page).to have_content user2.long_name
            expect(page).to have_content radio_option1
            expect(page).to have_content section1_text_value
          end
          within rows[2] do
            expect(page).to have_content user3.long_name
            expect(page).to have_content radio_option2
            expect(page).to have_content section2_text_value
          end
          within rows[3] do
            expect(page).to have_content user4.long_name
            expect(page).to have_content "#{I18n.t("gws/column.other_value")} : #{radio_other1}"
          end
        end
      end

      click_on I18n.t("ss.buttons.csv")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end
      wait_for_download

      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 4
        expect(csv_table.headers.length).to eq 6
        expect(csv_table.headers).to include(radio_column.name, section1_text_column.name, section2_text_column.name)
        csv_table[0].tap do |csv_row|
          expect(csv_row.length).to eq 6
          expect(csv_row[0]).to be_present
          expect(csv_row[1]).to eq user1.name
          expect(csv_row[2]).to eq user1.uid
          expect(csv_row[3]).to eq radio_option0
          expect(csv_row[4]).to be_blank
          expect(csv_row[5]).to be_blank
        end
        csv_table[1].tap do |csv_row|
          expect(csv_row.length).to eq 6
          expect(csv_row[0]).to be_present
          expect(csv_row[1]).to eq user2.name
          expect(csv_row[2]).to eq user2.uid
          expect(csv_row[3]).to eq radio_option1
          expect(csv_row[4]).to eq section1_text_value
          expect(csv_row[5]).to be_blank
        end
        csv_table[2].tap do |csv_row|
          expect(csv_row.length).to eq 6
          expect(csv_row[0]).to be_present
          expect(csv_row[1]).to eq user3.name
          expect(csv_row[2]).to eq user3.uid
          expect(csv_row[3]).to eq radio_option2
          expect(csv_row[4]).to be_blank
          expect(csv_row[5]).to eq section2_text_value
        end
        csv_table[3].tap do |csv_row|
          expect(csv_row.length).to eq 6
          expect(csv_row[0]).to be_present
          expect(csv_row[1]).to eq user4.name
          expect(csv_row[2]).to eq user4.uid
          option_value = with_default_locale { "#{I18n.t("gws/column.other_value")} : #{radio_other1}" }
          expect(csv_row[3]).to eq option_value
          expect(csv_row[4]).to be_blank
          expect(csv_row[5]).to be_blank
        end
      end
    end
  end
end
