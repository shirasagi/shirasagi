require 'spec_helper'

describe "gws_workflow2_form_applications", type: :feature, dbscope: :example, js: true, locale: %i[ja en] do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  context "basic crud" do
    let!(:destination_group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:destination_user1) { create :gws_user, cur_site: site, group_ids: admin.group_ids }
    let!(:route1) do
      create(
        :gws_workflow2_route, cur_site: site, cur_user: admin,
        readable_setting_range: "public", group_ids: [], user_ids: [ admin.id ], custom_group_ids: [])
    end
    let!(:cate1) { create :gws_workflow2_form_category, cur_site: site, cur_user: admin }
    let!(:purpose1) { create :gws_workflow2_form_purpose, cur_site: site, cur_user: admin }

    let(:name1) { "name-#{unique_id}" }
    let(:order1) { rand(1..10) }
    let(:approval_state1) { %w(without_approval with_approval).sample }
    let(:approval_state1_label) { I18n.t("gws/workflow2.options.approval_state.#{approval_state1}") }
    let(:agent_state1) { %w(disabled enabled).sample }
    let(:agent_state1_label) { I18n.t("gws/workflow2.options.agent_state.#{agent_state1}") }
    let(:description1) { Array.new(2) { "description-#{unique_id}" } }
    let(:memo1) { Array.new(2) { "memo-#{unique_id}" } }

    let!(:destination_group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:destination_user2) { create :gws_user, cur_site: site, group_ids: admin.group_ids }
    let!(:route2) do
      create(
        :gws_workflow2_route, cur_site: site, cur_user: admin,
        readable_setting_range: "public", group_ids: [], user_ids: [ admin.id ], custom_group_ids: [])
    end
    let!(:cate2) { create :gws_workflow2_form_category, cur_site: site, cur_user: admin }
    let!(:purpose2) { create :gws_workflow2_form_purpose, cur_site: site, cur_user: admin }

    let(:name2) { "name-#{unique_id}" }
    let(:order2) { rand(1..10) }
    let(:approval_state2) { %w(without_approval with_approval).sample }
    let(:approval_state2_label) { I18n.t("gws/workflow2.options.approval_state.#{approval_state2}") }
    let(:agent_state2) { %w(disabled enabled).sample }
    let(:agent_state2_label) { I18n.t("gws/workflow2.options.agent_state.#{agent_state2}") }
    let(:description2) { Array.new(2) { "description-#{unique_id}" } }
    let(:memo2) { Array.new(2) { "memo-#{unique_id}" } }

    it do
      #
      # Create
      #
      login_user admin, to: gws_workflow2_form_forms_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        # addon-basic
        fill_in "item[name]", with: name1
        fill_in "item[order]", with: order1
        choose approval_state1_label
        if approval_state1 == "with_approval"
          select route1.name, from: "item[default_route_id]"
        end
        select agent_state1_label, from: "item[agent_state]"
        fill_in "item[description]", with: description1.join("\n")
        fill_in "item[memo]", with: memo1.join("\n")

        # addon-gws-agents-addons-workflow2-form_category
        wait_for_cbox_opened { click_on I18n.t("gws.apis.categories.index") }
      end
      within_cbox do
        wait_for_cbox_closed { click_on cate1.name }
      end
      within "form#item-form" do
        expect(page).to have_css("#addon-gws-agents-addons-workflow2-form_category", text: cate1.name)

        # addon-gws-agents-addons-workflow2-form_purpose
        wait_for_cbox_opened { click_on I18n.t("gws/workflow2.apis.purposes.index") }
      end
      within_cbox do
        wait_for_cbox_closed { click_on purpose1.name }
      end
      within "form#item-form" do
        expect(page).to have_css("#addon-gws-agents-addons-workflow2-form_purpose", text: purpose1.name)

        # addon-gws-agents-addons-workflow2-destination_setting
        within "#addon-gws-agents-addons-workflow2-destination_setting" do
          wait_for_cbox_opened { click_on I18n.t("ss.apis.groups.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on destination_group1.trailing_name }
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-workflow2-destination_setting" do
          expect(page).to have_css("[data-id='#{destination_group1.id}']", text: destination_group1.name)

          wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on destination_user1.name }
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-workflow2-destination_setting" do
          expect(page).to have_css("[data-id='#{destination_user1.id}']", text: destination_user1.name)
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Form::Application.all.count).to eq 1
      Gws::Workflow2::Form::Application.all.first.tap do |form|
        # basic
        expect(form.name).to eq name1
        expect(form.order).to eq order1
        expect(form.approval_state).to eq approval_state1
        if approval_state1 == "with_approval"
          expect(form.default_route_id).to eq route1.id.to_s
        end
        expect(form.agent_state).to eq agent_state1
        expect(form.description).to eq description1.join("\r\n")
        expect(form.memo).to eq memo1.join("\r\n")
        # Gws::Addon::Workflow2::FormCategory
        expect(form.category_ids).to eq [ cate1.id ]
        # Gws::Addon::Workflow2::FormPurpose
        expect(form.purpose_ids).to eq [ purpose1.id ]
        # Gws::Addon::Workflow2::DestinationSetting
        expect(form.destination_group_ids).to eq [ destination_group1.id ]
        expect(form.destination_user_ids).to eq [ destination_user1.id ]
      end

      #
      # Update
      #
      visit gws_workflow2_form_forms_path(site: site)
      within ".list-item" do
        click_on name1
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        # addon-basic
        fill_in "item[name]", with: name2
        fill_in "item[order]", with: order2
        choose approval_state2_label
        if approval_state2 == "with_approval"
          select route2.name, from: "item[default_route_id]"
        end
        select agent_state2_label, from: "item[agent_state]"
        fill_in "item[description]", with: description2.join("\n")
        fill_in "item[memo]", with: memo2.join("\n")

        # addon-gws-agents-addons-workflow2-form_category
        within "#addon-gws-agents-addons-workflow2-form_category" do
          within "[data-id='#{cate1.id}']" do
            click_on I18n.t("ss.buttons.delete")
          end
          wait_for_cbox_opened { click_on I18n.t("gws.apis.categories.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on cate2.name }
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-workflow2-form_category" do
          expect(page).to have_css("[data-id='#{cate2.id}']", text: cate2.name)
        end

        # addon-gws-agents-addons-workflow2-form_purpose
        within "#addon-gws-agents-addons-workflow2-form_purpose" do
          within "[data-id='#{purpose1.id}']" do
            click_on I18n.t("ss.buttons.delete")
          end
          wait_for_cbox_opened { click_on I18n.t("gws/workflow2.apis.purposes.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on purpose2.name }
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-workflow2-form_purpose" do
          expect(page).to have_css("[data-id='#{purpose2.id}']", text: purpose2.name)
        end

        # addon-gws-agents-addons-workflow2-destination_setting
        within "#addon-gws-agents-addons-workflow2-destination_setting" do
          within "[data-id='#{destination_group1.id}']" do
            click_on I18n.t("ss.buttons.delete")
          end
          within "[data-id='#{destination_user1.id}']" do
            click_on I18n.t("ss.buttons.delete")
          end
          wait_for_cbox_opened { click_on I18n.t("ss.apis.groups.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on destination_group2.trailing_name }
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-workflow2-destination_setting" do
          expect(page).to have_css("[data-id='#{destination_group2.id}']", text: destination_group2.name)

          wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on destination_user2.name }
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-workflow2-destination_setting" do
          expect(page).to have_css("[data-id='#{destination_user2.id}']", text: destination_user2.name)
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Form::Application.all.count).to eq 1
      Gws::Workflow2::Form::Application.all.first.tap do |form|
        # basic
        expect(form.name).to eq name2
        expect(form.order).to eq order2
        expect(form.approval_state).to eq approval_state2
        if approval_state2 == "with_approval"
          expect(form.default_route_id).to eq route2.id.to_s
        end
        expect(form.agent_state).to eq agent_state2
        expect(form.description).to eq description2.join("\r\n")
        expect(form.memo).to eq memo2.join("\r\n")
        # Gws::Addon::Workflow2::FormCategory
        expect(form.category_ids).to eq [ cate2.id ]
        # Gws::Addon::Workflow2::FormPurpose
        expect(form.purpose_ids).to eq [ purpose2.id ]
        # Gws::Addon::Workflow2::DestinationSetting
        expect(form.destination_group_ids).to eq [ destination_group2.id ]
        expect(form.destination_user_ids).to eq [ destination_user2.id ]
      end

      #
      # Delete
      #
      visit gws_workflow2_form_forms_path(site: site)
      within ".list-item" do
        click_on name2
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Workflow2::Form::Application.all.count).to eq 0
    end
  end
end
