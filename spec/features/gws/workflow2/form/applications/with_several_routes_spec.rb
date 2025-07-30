require 'spec_helper'

describe "gws_workflow2_form_applications", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  before { login_user user }

  context "with readable routes" do
    context "with route having 'public' readable_setting_range" do
      let!(:route) { create :gws_workflow2_route, cur_site: site, cur_user: user, readable_setting_range: "public" }
      let(:name) { unique_id }

      it do
        visit gws_workflow2_form_forms_path(site: site)
        within ".nav-menu" do
          click_on I18n.t("ss.links.new")
        end
        wait_for_js_ready

        within "form#item-form" do
          expect(page).to have_css("option[value='my_group']", text: Gws::Workflow2::Route.t("my_group"))
          expect(page).to have_css("option[value='#{route.id}']", text: route.name)

          fill_in "item[name]", with: name
          select route.name, from: "item[default_route_id]"

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Gws::Workflow2::Form::Base.all.count).to eq 1
        Gws::Workflow2::Form::Base.all.first.tap do |application|
          expect(application).to be_a(Gws::Workflow2::Form::Application)
          expect(application.name).to eq name
          expect(application.default_route_id.to_s).to eq route.id.to_s
        end
      end
    end

    context "with route having 'select' readable_setting_range" do
      let!(:route) do
        create(
          :gws_workflow2_route, cur_site: site, cur_user: user, readable_setting_range: "select",
          readable_group_ids: gws_user.group_ids
        )
      end
      let(:name) { unique_id }

      it do
        visit gws_workflow2_form_forms_path(site: site)
        within ".nav-menu" do
          click_on I18n.t("ss.links.new")
        end
        wait_for_js_ready

        within "form#item-form" do
          expect(page).to have_css("option[value='my_group']", text: Gws::Workflow2::Route.t("my_group"))
          expect(page).to have_css("option[value='#{route.id}']", text: route.name)

          fill_in "item[name]", with: name
          select route.name, from: "item[default_route_id]"

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Gws::Workflow2::Form::Base.all.count).to eq 1
        Gws::Workflow2::Form::Base.all.first.tap do |application|
          expect(application).to be_a(Gws::Workflow2::Form::Application)
          expect(application.name).to eq name
          expect(application.default_route_id.to_s).to eq route.id.to_s
        end
      end
    end

    context "with route having 'private' readable_setting_range" do
      let!(:route) { create :gws_workflow2_route, cur_site: site, cur_user: user, readable_setting_range: "private" }
      let(:name) { unique_id }

      it do
        visit gws_workflow2_form_forms_path(site: site)
        within ".nav-menu" do
          click_on I18n.t("ss.links.new")
        end
        wait_for_js_ready

        within "form#item-form" do
          expect(page).to have_css("option[value='my_group']", text: Gws::Workflow2::Route.t("my_group"))
          expect(page).to have_css("option[value='#{route.id}']", text: route.name)

          fill_in "item[name]", with: name
          select route.name, from: "item[default_route_id]"

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Gws::Workflow2::Form::Base.all.count).to eq 1
        Gws::Workflow2::Form::Base.all.first.tap do |application|
          expect(application).to be_a(Gws::Workflow2::Form::Application)
          expect(application.name).to eq name
          expect(application.default_route_id.to_s).to eq route.id.to_s
        end
      end
    end
  end

  context "with none-readable routes" do
    let!(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
    let!(:route) { create :gws_workflow2_route, cur_site: site, cur_user: user1, readable_setting_range: "private" }
    let(:name) { unique_id }

    it do
      visit gws_workflow2_form_forms_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      wait_for_js_ready

      within "form#item-form" do
        expect(page).to have_css("option[value='my_group']", text: Gws::Workflow2::Route.t("my_group"))
        expect(page).to have_no_css("option[value='#{route.id}']")

        fill_in "item[name]", with: name
        select Gws::Workflow2::Route.t("my_group"), from: "item[default_route_id]"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Form::Base.all.count).to eq 1
      Gws::Workflow2::Form::Base.all.first.tap do |application|
        expect(application).to be_a(Gws::Workflow2::Form::Application)
        expect(application.name).to eq name
        expect(application.default_route_id.to_s).to eq "my_group"
      end
    end
  end
end
