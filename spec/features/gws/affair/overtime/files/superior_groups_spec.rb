require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before do
      create_affair_users

      # set superior_groups
      inferior_groups.each do |group|
        group.superior_group_ids = [superior_group.id]
        group.save!
      end

      # set capital
      capital.member_ids = Gws::User.all.map(&:id)
      capital.save!
    end

    let(:site) { affair_site }
    let(:user_sys) { affair_user("sys") }

    let(:superior_group) { Gws::Group.find_by(name: "庶務事務市/市長・副市長/総務部") }
    let(:inferior_groups) { Gws::Group.where(name: /^庶務事務市\/市長・副市長\/総務部\/総務課\//).to_a }
    let(:capital) { Gws::Affair::Capital.find_by(name: "1款1項1目 1-17") }

    # 市長・副市長
    let(:user716) { affair_user(716) } # 庶務事務市/市長・副市長

    # 総務部
    let(:user461) { affair_user(461) } # 庶務事務市/市長・副市長/総務部
    let(:user545) { affair_user(545) } # 庶務事務市/市長・副市長/総務部/総務課
    let(:user638) { affair_user(638) } # 庶務事務市/市長・副市長/総務部/総務課/人事担当
    let(:user586) { affair_user(586) } # 庶務事務市/市長・副市長/総務部/総務課/秘書広報担当

    # 市民生活部
    let(:user502) { affair_user(502) } # 庶務事務市/市長・副市長/市民生活部
    let(:user510) { affair_user(510) } # 庶務事務市/市長・副市長/市民生活部/税務課
    let(:user565) { affair_user(565) } # 庶務事務市/市長・副市長/市民生活部/税務課/市民税担当
    let(:user492) { affair_user(492) } # 庶務事務市/市長・副市長/市民生活部/税務課/固定資産税担当

    let(:superior_group1) { Gws::Group.find_by(name: "庶務事務市/市長・副市長") }
    let(:superior_group2) { Gws::Group.find_by(name: "庶務事務市/市長・副市長/総務部") }

    let(:new_path) { new_gws_affair_overtime_file_path(site: site, state: "mine") }
    let(:import_path) { import_gws_groups_path(site: site) }

    def check_superior(user, superior_group)
      login_user(user)
      visit new_path

      within "form#item-form" do
        expect(page).to have_css(".selected-capital", text: user.effective_capital(site).name)
        within "#addon-gws-agents-addons-group_permission" do
          expect(page).to have_css(".ajax-selected tr[data-id=\"#{superior_group.id}\"]")
        end
        fill_in "item[overtime_name]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))

      within ".mod-workflow-request" do
        select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
        click_on I18n.t("workflow.buttons.select")
        wait_cbox_open { click_on I18n.t("workflow.search_approvers.index") }
      end
      wait_for_cbox do
        within ".search-ui-form" do
          expect(page).to have_css("input[name=\"s[group]\"][value=\"#{superior_group.id}\"]")
        end
      end
    end

    it "#new" do
      Timecop.travel("2021/3/1") do
        login_user(user_sys)
        visit import_path

        check_superior(user461, superior_group1)
        check_superior(user545, superior_group2)
        check_superior(user638, superior_group2)
        check_superior(user586, superior_group2)
      end
    end
  end
end
