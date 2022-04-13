require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user_sup) { affair_user("sup") }

    # 市長・副市長
    let(:user_716) { affair_user(716) } # 庶務事務市/市長・副市長

    # 総務部
    let(:user_461) { affair_user(461) } # 庶務事務市/市長・副市長/総務部
    let(:user_545) { affair_user(545) } # 庶務事務市/市長・副市長/総務部/総務課
    let(:user_683) { affair_user(638) } # 庶務事務市/市長・副市長/総務部/総務課/人事担当
    let(:user_586) { affair_user(586) } # 庶務事務市/市長・副市長/総務部/総務課/秘書広報担当

    # 市民生活部
    let(:user_502) { affair_user(502) } # 庶務事務市/市長・副市長/市民生活部
    let(:user_510) { affair_user(510) } # 庶務事務市/市長・副市長/市民生活部/税務課
    let(:user_565) { affair_user(565) } # 庶務事務市/市長・副市長/市民生活部/税務課/市民税担当
    let(:user_492) { affair_user(492) } # 庶務事務市/市長・副市長/市民生活部/税務課/固定資産税担当

    let(:new_path) { new_gws_affair_overtime_file_path(site: site, state: "mine") }
    let(:import_path) { import_gws_groups_path(site: site) }

    def check_superior(user, superior_group)
      login_user(user)
      visit new_path

      within "#addon-gws-agents-addons-group_permission" do
        expect(page).to have_css(".ajax-selected td", text: superior_group)
      end
      within "form#item-form" do
        fill_in "item[overtime_name]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: "保存しました。")

      within ".mod-workflow-request" do
        select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
        click_on I18n.t("workflow.buttons.select")
        click_on I18n.t("workflow.search_approvers.index")
      end
      wait_for_cbox do
        within ".search-ui-form" do
          expect(page).to have_css("button.btn", text: superior_group)
        end
      end
    end

    it "#new" do
      Timecop.travel("2021/3/1") do
        login_user(user_sup)
        visit import_path

        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/superior_groups.csv"
          page.accept_confirm do
            click_on I18n.t("ss.links.import")
          end
        end

        capital = Gws::Affair::Capital.where(name: "1款1項1目 1-17").first
        capital.member_ids = Gws::User.all.map(&:id)
        capital.save!

        check_superior(user_461, "庶務事務市/市長・副市長")
        check_superior(user_545, "庶務事務市/市長・副市長/総務部")
        check_superior(user_683, "庶務事務市/市長・副市長/総務部")
        check_superior(user_586, "庶務事務市/市長・副市長/総務部")
      end
    end
  end
end
