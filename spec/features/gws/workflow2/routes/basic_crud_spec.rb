require 'spec_helper'

describe "gws_workflow2_routes", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let(:name) { unique_id }
  let(:pull_up) { %w(enabled disabled).sample }
  let(:pull_up_label) { I18n.t("ss.options.state.#{pull_up}") }
  let(:on_remand) { %w(back_to_init back_to_previous).sample }
  let(:on_remand_label) { I18n.t("workflow.options.on_remand.#{on_remand}") }
  let(:remark) { Array.new(2) { unique_id } }
  let(:required_count_level1) { %w(false 1).sample }
  let(:required_count_level1_label) do
    if required_count_level1 == "false"
      I18n.t("workflow.options.required_count.all")
    else
      I18n.t("workflow.options.required_count.minimum", required_count: required_count_level1)
    end
  end
  let(:required_count_level2) { %w(false 1).sample }
  let(:required_count_level2_label) do
    if required_count_level2 == "false"
      I18n.t("workflow.options.required_count.all")
    else
      I18n.t("workflow.options.required_count.minimum", required_count: required_count_level2)
    end
  end
  let(:required_count_level3) { %w(false 1).sample }
  let(:required_count_level3_label) do
    if required_count_level3 == "false"
      I18n.t("workflow.options.required_count.all")
    else
      I18n.t("workflow.options.required_count.minimum", required_count: required_count_level3)
    end
  end
  let(:approver_attachment_use_level1) { %w(enabled disabled).sample }
  let(:approver_attachment_use_level1_label) { I18n.t("ss.options.state.#{approver_attachment_use_level1}") }
  let(:approver_attachment_use_level2) { %w(enabled disabled).sample }
  let(:approver_attachment_use_level2_label) { I18n.t("ss.options.state.#{approver_attachment_use_level2}") }
  let(:approver_attachment_use_level3) { %w(enabled disabled).sample }
  let(:approver_attachment_use_level3_label) { I18n.t("ss.options.state.#{approver_attachment_use_level3}") }
  let(:circulation_attachment_use_level1) { %w(enabled disabled).sample }
  let(:circulation_attachment_use_level1_label) { I18n.t("ss.options.state.#{circulation_attachment_use_level1}") }
  let(:circulation_attachment_use_level2) { %w(enabled disabled).sample }
  let(:circulation_attachment_use_level2_label) { I18n.t("ss.options.state.#{circulation_attachment_use_level2}") }
  let(:circulation_attachment_use_level3) { %w(enabled disabled).sample }
  let(:circulation_attachment_use_level3_label) { I18n.t("ss.options.state.#{circulation_attachment_use_level3}") }

  before { login_gws_user }

  context "with superior" do
    let(:superior_label) { I18n.t("mongoid.attributes.gws/addon/group/affair_setting.superior_user_ids") }

    it do
      #
      # Create
      #
      visit gws_workflow2_routes_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end

      within "form#item-form" do
        fill_in "item[name]", with: name
        select pull_up_label, from: "item[pull_up]"
        select on_remand_label, from: "item[on_remand]"
        fill_in "item[remark]", with: remark.join("\n")

        # approver level 1
        within ".gws-workflow-route-approver-item[data-level='1']" do
          select required_count_level1_label, from: "item[required_counts][]"
          select approver_attachment_use_level1_label, from: "item[approver_attachment_uses][]"
          within "tr[data-type='new']" do
            select superior_label, from: "dummy-approver"
          end
        end

        # circulation level 1
        within ".gws-workflow-route-circulation-item[data-level='1']" do
          select circulation_attachment_use_level1_label, from: "item[circulation_attachment_uses][]"
          within "tr[data-type='new']" do
            select superior_label, from: "dummy-circulator"
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Route.all.count).to eq 1
      route = Gws::Workflow2::Route.all.first
      expect(route.site_id).to eq site.id
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.remark).to eq remark.join("\r\n")
      expect(route.approvers).to have(1).items
      route.approvers[0].tap do |approver|
        expect(approver[:level]).to eq 1
        expect(approver[:user_type]).to eq "superior"
        expect(approver[:user_id]).to eq "superior"
        expect(approver[:editable]).to be_blank
      end
      expect(route.required_counts).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      if required_count_level1 == "false"
        expect(route.required_counts[0]).to eq false
      else
        expect(route.required_counts[0]).to eq required_count_level1.to_i
      end
      expect(route.approver_attachment_uses).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      expect(route.approver_attachment_uses[0]).to eq approver_attachment_use_level1
      expect(route.circulations).to have(1).items
      route.circulations[0].tap do |circulation|
        expect(circulation[:level]).to eq 1
        expect(circulation[:user_type]).to eq "superior"
        expect(circulation[:user_id]).to eq "superior"
      end
      expect(route.circulation_attachment_uses).to have(Gws::Workflow2::Route::MAX_CIRCULATIONS).items
      expect(route.circulation_attachment_uses[0]).to eq circulation_attachment_use_level1

      #
      # Update
      #
      visit gws_workflow2_routes_path(site: site)
      click_on route.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_js_ready
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      route.reload
      expect(route.site_id).to eq site.id
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.remark).to eq remark.join("\r\n")
      expect(route.approvers).to have(1).items
      route.approvers[0].tap do |approver|
        expect(approver[:level]).to eq 1
        expect(approver[:user_type]).to eq "superior"
        expect(approver[:user_id]).to eq "superior"
        expect(approver[:editable]).to be_blank
      end
      expect(route.required_counts).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      if required_count_level1 == "false"
        expect(route.required_counts[0]).to eq false
      else
        expect(route.required_counts[0]).to eq required_count_level1.to_i
      end
      expect(route.approver_attachment_uses).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      expect(route.approver_attachment_uses[0]).to eq approver_attachment_use_level1
      expect(route.circulations).to have(1).items
      route.circulations[0].tap do |circulation|
        expect(circulation[:level]).to eq 1
        expect(circulation[:user_type]).to eq "superior"
        expect(circulation[:user_id]).to eq "superior"
      end
      expect(route.circulation_attachment_uses).to have(Gws::Workflow2::Route::MAX_CIRCULATIONS).items
      expect(route.circulation_attachment_uses[0]).to eq circulation_attachment_use_level1

      #
      # Delete
      #
      visit gws_workflow2_routes_path(site: site)
      click_on route.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end

      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { route.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "with gws/user_title" do
    let!(:title1) { create :gws_user_title, cur_site: site }
    let!(:title2) { create :gws_user_title, cur_site: site }
    let!(:title3) { create :gws_user_title, cur_site: site }
    let!(:title4) { create :gws_user_title, cur_site: site }
    let!(:title5) { create :gws_user_title, cur_site: site }
    let(:titles) { [ title1, title2, title3, title4, title5 ] }
    let(:approver_level1_title1) { titles.sample }
    let(:approver_level1_title2) { (titles - [approver_level1_title1]).sample }
    let(:approver_level2_title1) { titles.sample }
    let(:approver_level2_title2) { (titles - [approver_level2_title1]).sample }
    let(:approver_level3_title1) { titles.sample }
    let(:circulation_level1_title1) { titles.sample }
    let(:circulation_level2_title1) { titles.sample }
    let(:circulation_level3_title1) { titles.sample }

    it do
      #
      # Create
      #
      visit gws_workflow2_routes_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end

      within "form#item-form" do
        fill_in "item[name]", with: name
        select pull_up_label, from: "item[pull_up]"
        select on_remand_label, from: "item[on_remand]"
        fill_in "item[remark]", with: remark.join("\n")

        # approver level 1
        within ".gws-workflow-route-approver-item[data-level='1']" do
          select required_count_level1_label, from: "item[required_counts][]"
          select approver_attachment_use_level1_label, from: "item[approver_attachment_uses][]"
          within "tr[data-type='new']" do
            select approver_level1_title1.name, from: "dummy-approver"
          end
        end

        # approver level 2
        within ".gws-workflow-route-approver-item[data-level='2']" do
          select required_count_level2_label, from: "item[required_counts][]"
          select approver_attachment_use_level2_label, from: "item[approver_attachment_uses][]"
          within "tr[data-type='new']" do
            select approver_level2_title1.name, from: "dummy-approver"
          end
        end

        # approver level 3
        within ".gws-workflow-route-approver-item[data-level='3']" do
          select required_count_level3_label, from: "item[required_counts][]"
          select approver_attachment_use_level3_label, from: "item[approver_attachment_uses][]"
          within "tr[data-type='new']" do
            select approver_level3_title1.name, from: "dummy-approver"
          end
        end

        # circulation level 1
        within ".gws-workflow-route-circulation-item[data-level='1']" do
          select circulation_attachment_use_level1_label, from: "item[circulation_attachment_uses][]"
          within "tr[data-type='new']" do
            select circulation_level1_title1.name, from: "dummy-circulator"
          end
        end

        # circulation level 2
        within ".gws-workflow-route-circulation-item[data-level='2']" do
          select circulation_attachment_use_level2_label, from: "item[circulation_attachment_uses][]"
          within "tr[data-type='new']" do
            select circulation_level2_title1.name, from: "dummy-circulator"
          end
        end

        # circulation level 3
        within ".gws-workflow-route-circulation-item[data-level='3']" do
          select circulation_attachment_use_level3_label, from: "item[circulation_attachment_uses][]"
          within "tr[data-type='new']" do
            select circulation_level3_title1.name, from: "dummy-circulator"
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Route.all.count).to eq 1
      route = Gws::Workflow2::Route.all.first
      expect(route.site_id).to eq site.id
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.remark).to eq remark.join("\r\n")
      expect(route.approvers).to have(3).items
      expect(route.approvers_at(1)).to \
        include(level: 1, user_type: Gws::UserTitle.name, user_id: approver_level1_title1.id, editable: "")
      expect(route.approvers_at(2)).to \
        include(level: 2, user_type: Gws::UserTitle.name, user_id: approver_level2_title1.id, editable: "")
      expect(route.approvers_at(3)).to \
        include(level: 3, user_type: Gws::UserTitle.name, user_id: approver_level3_title1.id, editable: "")
      expect(route.required_counts).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      expect(route.required_counts[0]).to eq required_count_level1 == "false" ? false : required_count_level1.to_i
      expect(route.required_counts[1]).to eq required_count_level2 == "false" ? false : required_count_level2.to_i
      expect(route.required_counts[2]).to eq required_count_level3 == "false" ? false : required_count_level3.to_i
      expect(route.approver_attachment_uses).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      expect(route.approver_attachment_uses[0]).to eq approver_attachment_use_level1
      expect(route.approver_attachment_uses[1]).to eq approver_attachment_use_level2
      expect(route.approver_attachment_uses[2]).to eq approver_attachment_use_level3
      expect(route.circulations).to have(3).items
      expect(route.circulations_at(1)).to \
        include(level: 1, user_type: Gws::UserTitle.name, user_id: circulation_level1_title1.id)
      expect(route.circulations_at(2)).to \
        include(level: 2, user_type: Gws::UserTitle.name, user_id: circulation_level2_title1.id)
      expect(route.circulations_at(3)).to \
        include(level: 3, user_type: Gws::UserTitle.name, user_id: circulation_level3_title1.id)
      expect(route.circulation_attachment_uses).to have(Gws::Workflow2::Route::MAX_CIRCULATIONS).items
      expect(route.circulation_attachment_uses[0]).to eq circulation_attachment_use_level1
      expect(route.circulation_attachment_uses[1]).to eq circulation_attachment_use_level2
      expect(route.circulation_attachment_uses[2]).to eq circulation_attachment_use_level3

      #
      # Update
      #
      visit gws_workflow2_routes_path(site: site)
      click_on route.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end

      within "form#item-form" do
        # approver level 1: change
        within ".gws-workflow-route-approver-item[data-level='1']" do
          within "tr[data-type='#{approver_level1_title1.class.name}'][data-id='#{approver_level1_title1.id}']" do
            select approver_level1_title2.name, from: "dummy-approver"
          end
        end

        # approver level 2: add
        within ".gws-workflow-route-approver-item[data-level='2']" do
          within "tr[data-type='new']" do
            select approver_level2_title2.name, from: "dummy-approver"
          end
        end

        # approver level 3: delete
        within ".gws-workflow-route-approver-item[data-level='3']" do
          within "tr[data-type='#{approver_level3_title1.class.name}'][data-id='#{approver_level3_title1.id}']" do
            click_on I18n.t("ss.buttons.delete")
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      route.reload
      expect(route.site_id).to eq site.id
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.remark).to eq remark.join("\r\n")
      expect(route.approvers).to have(3).items
      expect(route.approvers_at(1)).to \
        include(level: 1, user_type: Gws::UserTitle.name, user_id: approver_level1_title2.id, editable: "")
      expect(route.approvers_at(2)).to \
        include(
          { level: 2, user_type: Gws::UserTitle.name, user_id: approver_level2_title1.id, editable: "" },
          { level: 2, user_type: Gws::UserTitle.name, user_id: approver_level2_title2.id, editable: "" })
      expect(route.approvers_at(3)).to be_blank

      #
      # Delete
      #
      visit gws_workflow2_routes_path(site: site)
      click_on route.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end

      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { route.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "with gws/user_occupation" do
    let!(:occupation1) { create :gws_user_occupation, cur_site: site }
    let!(:occupation2) { create :gws_user_occupation, cur_site: site }
    let!(:occupation3) { create :gws_user_occupation, cur_site: site }
    let!(:occupation4) { create :gws_user_occupation, cur_site: site }
    let!(:occupation5) { create :gws_user_occupation, cur_site: site }
    let(:occupations) { [ occupation1, occupation2, occupation3, occupation4, occupation5 ] }
    let(:approver_level1_occupation1) { occupations.sample }
    let(:approver_level1_occupation2) { (occupations - [approver_level1_occupation1]).sample }
    let(:approver_level2_occupation1) { occupations.sample }
    let(:approver_level2_occupation2) { (occupations - [approver_level2_occupation1]).sample }
    let(:approver_level3_occupation1) { occupations.sample }
    let(:circulation_level1_occupation1) { occupations.sample }
    let(:circulation_level2_occupation1) { occupations.sample }
    let(:circulation_level3_occupation1) { occupations.sample }

    it do
      #
      # Create
      #
      visit gws_workflow2_routes_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end

      within "form#item-form" do
        fill_in "item[name]", with: name
        select pull_up_label, from: "item[pull_up]"
        select on_remand_label, from: "item[on_remand]"
        fill_in "item[remark]", with: remark.join("\n")

        # approver level 1
        within ".gws-workflow-route-approver-item[data-level='1']" do
          select required_count_level1_label, from: "item[required_counts][]"
          select approver_attachment_use_level1_label, from: "item[approver_attachment_uses][]"
          within "tr[data-type='new']" do
            select approver_level1_occupation1.name, from: "dummy-approver"
          end
        end

        # approver level 2
        within ".gws-workflow-route-approver-item[data-level='2']" do
          select required_count_level2_label, from: "item[required_counts][]"
          select approver_attachment_use_level2_label, from: "item[approver_attachment_uses][]"
          within "tr[data-type='new']" do
            select approver_level2_occupation1.name, from: "dummy-approver"
          end
        end

        # approver level 3
        within ".gws-workflow-route-approver-item[data-level='3']" do
          select required_count_level3_label, from: "item[required_counts][]"
          select approver_attachment_use_level3_label, from: "item[approver_attachment_uses][]"
          within "tr[data-type='new']" do
            select approver_level3_occupation1.name, from: "dummy-approver"
          end
        end

        # circulation level 1
        within ".gws-workflow-route-circulation-item[data-level='1']" do
          select circulation_attachment_use_level1_label, from: "item[circulation_attachment_uses][]"
          within "tr[data-type='new']" do
            select circulation_level1_occupation1.name, from: "dummy-circulator"
          end
        end

        # circulation level 2
        within ".gws-workflow-route-circulation-item[data-level='2']" do
          select circulation_attachment_use_level2_label, from: "item[circulation_attachment_uses][]"
          within "tr[data-type='new']" do
            select circulation_level2_occupation1.name, from: "dummy-circulator"
          end
        end

        # circulation level 3
        within ".gws-workflow-route-circulation-item[data-level='3']" do
          select circulation_attachment_use_level3_label, from: "item[circulation_attachment_uses][]"
          within "tr[data-type='new']" do
            select circulation_level3_occupation1.name, from: "dummy-circulator"
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Route.all.count).to eq 1
      route = Gws::Workflow2::Route.all.first
      expect(route.site_id).to eq site.id
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.remark).to eq remark.join("\r\n")
      expect(route.approvers).to have(3).items
      expect(route.approvers_at(1)).to \
        include(level: 1, user_type: Gws::UserOccupation.name, user_id: approver_level1_occupation1.id, editable: "")
      expect(route.approvers_at(2)).to \
        include(level: 2, user_type: Gws::UserOccupation.name, user_id: approver_level2_occupation1.id, editable: "")
      expect(route.approvers_at(3)).to \
        include(level: 3, user_type: Gws::UserOccupation.name, user_id: approver_level3_occupation1.id, editable: "")
      expect(route.required_counts).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      expect(route.required_counts[0]).to eq required_count_level1 == "false" ? false : required_count_level1.to_i
      expect(route.required_counts[1]).to eq required_count_level2 == "false" ? false : required_count_level2.to_i
      expect(route.required_counts[2]).to eq required_count_level3 == "false" ? false : required_count_level3.to_i
      expect(route.approver_attachment_uses).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      expect(route.approver_attachment_uses[0]).to eq approver_attachment_use_level1
      expect(route.approver_attachment_uses[1]).to eq approver_attachment_use_level2
      expect(route.approver_attachment_uses[2]).to eq approver_attachment_use_level3
      expect(route.circulations).to have(3).items
      expect(route.circulations_at(1)).to \
        include(level: 1, user_type: Gws::UserOccupation.name, user_id: circulation_level1_occupation1.id)
      expect(route.circulations_at(2)).to \
        include(level: 2, user_type: Gws::UserOccupation.name, user_id: circulation_level2_occupation1.id)
      expect(route.circulations_at(3)).to \
        include(level: 3, user_type: Gws::UserOccupation.name, user_id: circulation_level3_occupation1.id)
      expect(route.circulation_attachment_uses).to have(Gws::Workflow2::Route::MAX_CIRCULATIONS).items
      expect(route.circulation_attachment_uses[0]).to eq circulation_attachment_use_level1
      expect(route.circulation_attachment_uses[1]).to eq circulation_attachment_use_level2
      expect(route.circulation_attachment_uses[2]).to eq circulation_attachment_use_level3

      #
      # Update
      #
      visit gws_workflow2_routes_path(site: site)
      click_on route.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end

      within "form#item-form" do
        # approver level 1: change
        within ".gws-workflow-route-approver-item[data-level='1']" do
          within "tr[data-type='#{approver_level1_occupation1.class.name}'][data-id='#{approver_level1_occupation1.id}']" do
            select approver_level1_occupation2.name, from: "dummy-approver"
          end
        end

        # approver level 2: add
        within ".gws-workflow-route-approver-item[data-level='2']" do
          within "tr[data-type='new']" do
            select approver_level2_occupation2.name, from: "dummy-approver"
          end
        end

        # approver level 3: delete
        within ".gws-workflow-route-approver-item[data-level='3']" do
          within "tr[data-type='#{approver_level3_occupation1.class.name}'][data-id='#{approver_level3_occupation1.id}']" do
            click_on I18n.t("ss.buttons.delete")
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      route.reload
      expect(route.site_id).to eq site.id
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.remark).to eq remark.join("\r\n")
      expect(route.approvers).to have(3).items
      expect(route.approvers_at(1)).to \
        include(level: 1, user_type: Gws::UserOccupation.name, user_id: approver_level1_occupation2.id, editable: "")
      expect(route.approvers_at(2)).to \
        include(
          { level: 2, user_type: Gws::UserOccupation.name, user_id: approver_level2_occupation1.id, editable: "" },
          { level: 2, user_type: Gws::UserOccupation.name, user_id: approver_level2_occupation2.id, editable: "" })
      expect(route.approvers_at(3)).to be_blank

      #
      # Delete
      #
      visit gws_workflow2_routes_path(site: site)
      click_on route.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end

      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { route.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "with specific / individual user" do
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:approver_level1_user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: gws_user.gws_role_ids }
    let!(:approver_level2_user1) { create :gws_user, group_ids: [ group2.id ], gws_role_ids: gws_user.gws_role_ids }
    let!(:approver_level3_user1) { create :gws_user, group_ids: [ group3.id ], gws_role_ids: gws_user.gws_role_ids }
    let!(:circulation_level1_user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: gws_user.gws_role_ids }
    let!(:circulation_level2_user1) { create :gws_user, group_ids: [ group2.id ], gws_role_ids: gws_user.gws_role_ids }
    let!(:circulation_level3_user1) { create :gws_user, group_ids: [ group3.id ], gws_role_ids: gws_user.gws_role_ids }

    it do
      #
      # Create
      #
      visit gws_workflow2_routes_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end

      within "form#item-form" do
        fill_in "item[name]", with: name
        select pull_up_label, from: "item[pull_up]"
        select on_remand_label, from: "item[on_remand]"
        fill_in "item[remark]", with: remark.join("\n")

        # approver level 1
        within ".gws-workflow-route-approver-item[data-level='1']" do
          select required_count_level1_label, from: "item[required_counts][]"
          select approver_attachment_use_level1_label, from: "item[approver_attachment_uses][]"
          wait_for_cbox_opened do
            within "tr[data-type='new']" do
              select I18n.t("gws/workflow2.select_other_approvers"), from: "dummy-approver"
            end
          end
          within_dialog do
            within ".dd-group" do
              click_on gws_user.groups.first.name
              within ".dropdown-container" do
                click_on site.name
              end
            end
            wait_for_cbox_closed { click_on approver_level1_user1.name }
          end
        end
        wait_for_js_ready

        # approver level 2
        within ".gws-workflow-route-approver-item[data-level='2']" do
          select required_count_level2_label, from: "item[required_counts][]"
          select approver_attachment_use_level2_label, from: "item[approver_attachment_uses][]"
          wait_for_cbox_opened do
            within "tr[data-type='new']" do
              select I18n.t("gws/workflow2.select_other_approvers"), from: "dummy-approver"
            end
          end
          within_dialog do
            within ".dd-group" do
              click_on gws_user.groups.first.name
              within ".dropdown-container" do
                click_on site.name
              end
            end
            wait_for_cbox_closed { click_on approver_level2_user1.name }
          end
        end
        wait_for_js_ready

        # approver level 3
        within ".gws-workflow-route-approver-item[data-level='3']" do
          select required_count_level3_label, from: "item[required_counts][]"
          select approver_attachment_use_level3_label, from: "item[approver_attachment_uses][]"
          wait_for_cbox_opened do
            within "tr[data-type='new']" do
              select I18n.t("gws/workflow2.select_other_approvers"), from: "dummy-approver"
            end
          end
          within_dialog do
            within ".dd-group" do
              click_on gws_user.groups.first.name
              within ".dropdown-container" do
                click_on site.name
              end
            end
            wait_for_cbox_closed { click_on approver_level3_user1.name }
          end
        end
        wait_for_js_ready

        # circulation level 1
        within ".gws-workflow-route-circulation-item[data-level='1']" do
          select circulation_attachment_use_level1_label, from: "item[circulation_attachment_uses][]"
          wait_for_cbox_opened do
            within "tr[data-type='new']" do
              select I18n.t("gws/workflow2.select_other_circulations"), from: "dummy-circulator"
            end
          end
          within_dialog do
            within ".dd-group" do
              click_on gws_user.groups.first.name
              within ".dropdown-container" do
                click_on site.name
              end
            end
            wait_for_cbox_closed { click_on circulation_level1_user1.name }
          end
        end
        wait_for_js_ready

        # circulation level 2
        within ".gws-workflow-route-circulation-item[data-level='2']" do
          select circulation_attachment_use_level2_label, from: "item[circulation_attachment_uses][]"
          wait_for_cbox_opened do
            within "tr[data-type='new']" do
              select I18n.t("gws/workflow2.select_other_circulations"), from: "dummy-circulator"
            end
          end
          within_dialog do
            within ".dd-group" do
              click_on gws_user.groups.first.name
              within ".dropdown-container" do
                click_on site.name
              end
            end
            wait_for_cbox_closed { click_on circulation_level2_user1.name }
          end
        end
        wait_for_js_ready

        # circulation level 3
        within ".gws-workflow-route-circulation-item[data-level='3']" do
          select circulation_attachment_use_level3_label, from: "item[circulation_attachment_uses][]"
          wait_for_cbox_opened do
            within "tr[data-type='new']" do
              select I18n.t("gws/workflow2.select_other_circulations"), from: "dummy-circulator"
            end
          end
          within_dialog do
            within ".dd-group" do
              click_on gws_user.groups.first.name
              within ".dropdown-container" do
                click_on site.name
              end
            end
            wait_for_cbox_closed { click_on circulation_level3_user1.name }
          end
        end
        wait_for_js_ready

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Route.all.count).to eq 1
      route = Gws::Workflow2::Route.all.first
      expect(route.site_id).to eq site.id
      expect(route.name).to eq name
      expect(route.pull_up).to eq pull_up
      expect(route.on_remand).to eq on_remand
      expect(route.remark).to eq remark.join("\r\n")
      expect(route.approvers).to have(3).items
      expect(route.approvers_at(1)).to \
        include(level: 1, user_type: Gws::User.name, user_id: approver_level1_user1.id, editable: "")
      expect(route.approvers_at(2)).to \
        include(level: 2, user_type: Gws::User.name, user_id: approver_level2_user1.id, editable: "")
      expect(route.approvers_at(3)).to \
        include(level: 3, user_type: Gws::User.name, user_id: approver_level3_user1.id, editable: "")
      expect(route.required_counts).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      expect(route.required_counts[0]).to eq required_count_level1 == "false" ? false : required_count_level1.to_i
      expect(route.required_counts[1]).to eq required_count_level2 == "false" ? false : required_count_level2.to_i
      expect(route.required_counts[2]).to eq required_count_level3 == "false" ? false : required_count_level3.to_i
      expect(route.approver_attachment_uses).to have(Gws::Workflow2::Route::MAX_APPROVERS).items
      expect(route.approver_attachment_uses[0]).to eq approver_attachment_use_level1
      expect(route.approver_attachment_uses[1]).to eq approver_attachment_use_level2
      expect(route.approver_attachment_uses[2]).to eq approver_attachment_use_level3
      expect(route.circulations).to have(3).items
      expect(route.circulations_at(1)).to \
        include(level: 1, user_type: Gws::User.name, user_id: circulation_level1_user1.id)
      expect(route.circulations_at(2)).to \
        include(level: 2, user_type: Gws::User.name, user_id: circulation_level2_user1.id)
      expect(route.circulations_at(3)).to \
        include(level: 3, user_type: Gws::User.name, user_id: circulation_level3_user1.id)
      expect(route.circulation_attachment_uses).to have(Gws::Workflow2::Route::MAX_CIRCULATIONS).items
      expect(route.circulation_attachment_uses[0]).to eq circulation_attachment_use_level1
      expect(route.circulation_attachment_uses[1]).to eq circulation_attachment_use_level2
      expect(route.circulation_attachment_uses[2]).to eq circulation_attachment_use_level3
    end
  end
end
