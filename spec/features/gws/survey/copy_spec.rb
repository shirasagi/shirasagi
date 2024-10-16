require 'spec_helper'

describe "gws_survey", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user2) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate) { create(:gws_survey_category, cur_site: site) }

  let!(:form) do
    create(
      :gws_survey_form, cur_site: site, cur_user: gws_user, category_ids: [ cate.id ],
      readable_setting_range: 'public')
  end
  let(:column_options) { Array.new(3) { "option-#{unique_id}" } }
  let!(:column1) do
    create(:gws_column_radio_button, cur_site: site, form: form, select_options: column_options, order: 10)
  end
  let!(:column2) do
    create(:gws_column_section, cur_site: site, form: form, order: 20)
  end

  before do
    column1.branch_section_ids = [column2.id.to_s]
    column1.save
  end

  context "copy" do
    let(:copy_name) { "copy-#{unique_id}" }
    let(:copy_anonymous_state) { %w(disabled enabled).sample }
    let(:copy_anonymous_state_label) { I18n.t("ss.options.state.#{copy_anonymous_state}") }
    let(:copy_file_state) { %w(closed public).sample }
    let(:copy_file_state_label) { I18n.t("ss.options.state.#{copy_file_state}") }

    before do
      expect(form.notification_noticed_at).to be_blank
      form.update(state: 'public')
    end

    it do
      Gws::Survey::Form.find(form.id).tap do |form0|
        expect(form0.answered_users_hash).to be_blank
        expect(form0.notification_noticed_at).to be_present
      end

      # answer by gws_user
      login_gws_user
      visit gws_survey_main_path(site: site)
      click_on form.name
      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options[0]
        end
        click_on I18n.t("ss.buttons.answer")
      end
      wait_for_notice I18n.t("ss.notice.answered")

      # answer by user1
      login_user user1
      visit gws_survey_main_path(site: site)
      click_on form.name
      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options[2]
        end
        click_on I18n.t("ss.buttons.answer")
      end
      wait_for_notice I18n.t("ss.notice.answered")

      Gws::Survey::Form.find(form.id).tap do |form0|
        expect(form0.files.count).to eq 2
        expect(form0.answered_users_hash).to include(gws_user.id.to_s, user1.id.to_s)
        expect(form0.answered_users_hash.count).to eq form0.files.count
      end

      # copy
      login_gws_user
      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form.name
      click_on I18n.t("ss.links.copy")

      within "form#item-form" do
        fill_in "item[name]", with: copy_name
        select copy_anonymous_state_label, from: 'item[anonymous_state]'
        select copy_file_state_label, from: 'item[file_state]'
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.copied")

      copy_form = Gws::Survey::Form.where(name: copy_name).first.tap do |copy_form|
        expect(copy_form.name).to eq copy_name
        expect(copy_form.description).to eq form.description
        expect(copy_form.order).to eq form.order
        expect(copy_form.state).to eq "closed"
        expect(copy_form.memo).to eq form.memo
        expect(copy_form.due_date).to eq form.due_date
        expect(copy_form.release_date).to eq form.release_date
        expect(copy_form.close_date).to eq form.close_date
        expect(copy_form.anonymous_state).to eq copy_anonymous_state
        expect(copy_form.file_state).to eq copy_file_state
        expect(copy_form.file_edit_state).to eq form.file_edit_state
        expect(copy_form.contributor_model).to eq form.contributor_model
        expect(copy_form.contributor_id).to eq form.contributor_id
        expect(copy_form.contributor_name).to eq form.contributor_name
        expect(copy_form.columns.count).to eq 2
        copy_form.columns.to_a.tap do |copy_columns|
          copy_columns[0].tap do |copy_column|
            expect(copy_column.id).not_to eq column1.id
            expect(copy_column.name).to eq column1.name
            expect(copy_column.order).to eq column1.order
            expect(copy_column.required).to eq column1.required
            expect(copy_column.tooltips).to eq column1.tooltips
            expect(copy_column.prefix_label).to eq column1.prefix_label
            expect(copy_column.postfix_label).to eq column1.postfix_label
            expect(copy_column.prefix_explanation).to eq column1.prefix_explanation
            expect(copy_column.postfix_explanation).to eq column1.postfix_explanation
            expect(copy_column.select_options).to eq column1.select_options
            expect(copy_column.branch_section_ids).to include copy_form.columns[1].id.to_s
          end
          copy_columns[1].tap do |copy_column|
            expect(copy_column.id).not_to eq column2.id
            expect(copy_column.name).to eq column2.name
          end
        end
        expect(copy_form.category_ids).to eq form.category_ids
        expect(copy_form.files.count).to eq 0
        expect(copy_form.readable_setting_range).to eq form.readable_setting_range
        expect(copy_form.readable_group_ids).to eq form.readable_group_ids
        expect(copy_form.readable_member_ids).to eq form.readable_member_ids
        expect(copy_form.readable_custom_group_ids).to eq form.readable_custom_group_ids
        expect(copy_form.group_ids).to eq form.group_ids
        expect(copy_form.custom_group_ids).to eq form.custom_group_ids
        expect(copy_form.answered_users_hash).to be_blank
        expect(copy_form.notification_notice_state).to eq form.notification_notice_state
        expect(copy_form.notification_noticed_at).to be_blank
      end

      # publish
      click_on I18n.t("gws/workflow.links.publish")

      within "form#item-form" do
        click_on(I18n.t("ss.buttons.save"))
      end

      expect(Gws::Survey::Form.all.count).to eq 2

      # answer by user2
      login_user user2
      visit gws_survey_main_path(site: site)

      click_on copy_form.name
      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options[1]
        end
        click_on I18n.t("ss.buttons.answer")
      end
      wait_for_notice I18n.t("ss.notice.answered")

      # check answers
      Gws::Survey::Form.find(form.id).tap do |form0|
        expect(form0.files.count).to eq 2
        expect(form0.answered_users_hash).to include(gws_user.id.to_s, user1.id.to_s)
        expect(form0.answered_users_hash.count).to eq form0.files.count
      end

      Gws::Survey::Form.where(name: copy_name).first.then do |copy_form|
        answers = copy_form.files.to_a
        expect(answers.count).to eq 1
        expect(copy_form.answered_users_hash).to include(user2.id.to_s)
        expect(copy_form.answered_users_hash.count).to eq answers.count

        answer = answers.first
        expect(answer.user_name).to eq user2.name
        answer.column_values.to_a.tap do |answer_column_values|
          expect(answer_column_values.count).to eq 1
          expect(answer.column_values[0].value).to eq column_options[1]
        end
      end
    end
  end
end
