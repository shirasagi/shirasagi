require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  context "site's user_public_profiles" do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let!(:user1) do
      Gws::User.create(
        name: "name-#{unique_id}", uid: "uid-#{unique_id}", email: unique_email, in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ],
        lang: SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s)
    end
    let!(:user2) do
      Gws::User.create(
        name: "name-#{unique_id}", uid: "uid-#{unique_id}", email: unique_email, in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ],
        lang: SS::LocaleSupport.current_lang ? SS::LocaleSupport.current_lang.to_s : I18n.locale.to_s)
    end
    let!(:item) do
      create(
        :gws_workflow_file, cur_site: site, cur_user: admin,
        workflow_user_id: admin.id,
        workflow_state: "approve",
        workflow_approvers: [
          { "level" => 1, "user_id" => user1.id, editable: "", state: "approve", comment: "comment-#{unique_id}" },
        ],
        workflow_required_counts: [ false ],
        workflow_circulations: [
          { "level" => 1, "user_id" => user2.id, state: "seen", comment: "comment-#{unique_id}" },
        ]
      )
    end

    before { login_gws_user }

    context "when user_public_profiles are empty" do
      before do
        site.user_public_profiles = []
        site.save
      end

      it do
        visit gws_workflow_files_main_path(site: site)
        click_on item.name
        within "#addon-workflow-agents-addons-approver" do
          expect(page).to have_css(".request-setting .workflow-route-start", text: I18n.t("workflow.buttons.select"))
          expect(page).to have_css(".see", text: "#{user1.long_name}(#{user1.email})")
          expect(page).to have_css(".see", text: "#{user2.long_name}(#{user2.email})")
        end
      end
    end

    context "when user_public_profiles only contains uid" do
      before do
        site.user_public_profiles = %w(uid)
        site.save
      end

      it do
        visit gws_workflow_files_main_path(site: site)
        click_on item.name
        within "#addon-workflow-agents-addons-approver" do
          expect(page).to have_css(".request-setting .workflow-route-start", text: I18n.t("workflow.buttons.select"))
          expect(page).to have_css(".see", text: user1.long_name)
          expect(page).to have_css(".see", text: user2.long_name)
          expect(page).to have_no_content(user1.email)
          expect(page).to have_no_content(user2.email)
        end
      end
    end

    context "when user_public_profiles only contains email" do
      before do
        site.user_public_profiles = %w(email)
        site.save
      end

      it do
        visit gws_workflow_files_main_path(site: site)
        click_on item.name
        within "#addon-workflow-agents-addons-approver" do
          expect(page).to have_css(".request-setting .workflow-route-start", text: I18n.t("workflow.buttons.select"))
          expect(page).to have_css(".see", text: "#{user1.name}(#{user1.email})")
          expect(page).to have_css(".see", text: "#{user2.name}(#{user2.email})")
          expect(page).to have_no_content(user1.uid)
          expect(page).to have_no_content(user2.uid)
        end
      end
    end
  end
end
