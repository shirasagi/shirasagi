require 'spec_helper'

describe "gws_survey", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) do
    create(
      :gws_user, uid: "U001", organization_uid: "U001", organization_id: gws_user.groups.first.id,
      group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
    )
  end
  let!(:user2) do
    create(
      :gws_user, uid: "U002", organization_uid: "U002", organization_id: gws_user.groups.first.id,
      group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
    )
  end
  let!(:cate) { create(:gws_survey_category, cur_site: site) }

  before do
    site.canonical_scheme = 'http'
    site.canonical_domain = 'www.example.jp'
    site.save!
  end

  context "basic crud" do
    let(:form_name) { "form-#{unique_id}" }
    let(:column_name) { "column-#{unique_id}" }
    let(:column_options) { [ "option-#{unique_id}", "option-#{unique_id}", "option-#{unique_id}" ] }

    it do
      login_gws_user

      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: form_name
        choose I18n.t("gws.options.readable_setting_range.public")
        click_on I18n.t("gws.apis.categories.index")
      end
      wait_for_cbox do
        expect(page).to have_content(cate.name)
        click_on cate.name
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Gws::Survey::Form.all.count).to eq 1

      click_on(I18n.t('gws/workflow.columns.index'))

      click_on(I18n.t("ss.links.new"))
      click_on(I18n.t("mongoid.models.gws/column/radio_button"))
      within "form#item-form" do
        fill_in "item[name]", with: column_name
        fill_in "item[select_options]", with: column_options.join("\n")
        click_on(I18n.t("ss.buttons.save"))
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      # click print
      click_on(form_name)
      click_on(I18n.t("ss.buttons.print"))
      expect(page).to have_text(column_name)
      click_on(I18n.t("ss.links.back"))

      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form_name
      click_on I18n.t("gws/workflow.links.publish")

      within "form" do
        click_on(I18n.t("ss.buttons.save"))
      end

      expect(Gws::Survey::Form.all.count).to eq 1
      form = Gws::Survey::Form.all.site(site).find_by(name: form_name)

      expect(Gws::Job::Log.all.where(class_name: Gws::Survey::NotificationJob.name).count).to eq 1
      Gws::Job::Log.all.first(class_name: Gws::Survey::NotificationJob.name).tap do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end

      expect(SS::Notification.all.count).to eq 1
      SS::Notification.all.first.tap do |notice|
        subject = I18n.t("gws_notification.#{Gws::Survey::Form.model_name.i18n_key}.subject", name: form.name, default: form.name)
        expect(notice.subject).to eq subject
        expect(notice.member_ids).to include(user1.id, user2.id)
      end

      #
      # answer by user1
      #
      login_user user1
      visit gws_survey_main_path(site: site)
      click_on form_name

      # click print
      click_on(I18n.t("ss.links.print"))
      expect(page).to have_text(column_name)
      click_on(I18n.t("ss.links.back"))

      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options.sample
        end
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      #
      # answer by user2
      #
      login_user user2
      visit gws_survey_main_path(site: site)
      click_on form_name

      # click print
      click_on(I18n.t("ss.links.print"))
      expect(page).to have_text(column_name)
      click_on(I18n.t("ss.links.back"))

      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options.sample
        end
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      #
      # check answers
      #
      login_gws_user
      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form_name

      click_on I18n.t("gws/survey.view_files")
      expect(page).to have_text(user1.name)
      expect(page).to have_text(user2.name)

      within ".operations" do
        click_on "CSV"
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end
      wait_for_download

      csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
      expect(csv.length).to eq 2
      expect(csv[0][Gws::Survey::File.t(:updated)].present?).to be_truthy
      expect(csv[0][Gws::User.t(:name)]).to eq user1.name
      expect(csv[0][Gws::User.t(:organization_uid)]).to eq user1.organization_uid

      # zip
      click_on I18n.t("ss.links.back_to_index")
      within ".operations" do
        click_on I18n.t("gws/survey.buttons.zip_all_files")
      end

      #
      # aggregate
      #
      #click_on I18n.t("ss.links.back_to_index")
      click_on I18n.t("gws/survey.tabs.summary")
      within ".gws-survey" do
        expect(page).to have_css("dd", text: csv.length)
      end

      #
      # delete_all
      #
      within ".current-navi" do
        click_on "管理一覧"
      end

      within ".list-items" do
        expect(page).to have_css(".info", text: form_name)
        find("input[value]").check
      end

      within '.list-head' do
        page.accept_confirm do
          click_button I18n.t('ss.links.delete')
        end
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))
    end
  end
end
