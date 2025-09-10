require 'spec_helper'

describe "gws_apis_users", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  context "pagination" do
    # このテストは1ページに表示する項目数が多ければ多いほど良いが、10 に留めておく。
    let(:max_items_per_page) { 10 }

    before do
      @save_max_items_per_page = SS.max_items_per_page
      SS.max_items_per_page = max_items_per_page

      names = Array.new(max_items_per_page * 2) { unique_id }
      names.shuffle!

      (max_items_per_page * 2).times do |i|
        user = create(
          :gws_user, name: names[i], email: "#{names[i]}@example.jp", uid: nil, organization_uid: nil, title_ids: [],
          group_ids: admin.group_ids, gws_role_ids: admin.gws_role_ids)
        expect(user.title_orders).to be_blank
      end
    end

    after do
      SS.max_items_per_page = @save_max_items_per_page
    end

    it do
      login_user admin, to: gws_schedule_main_path(site: site)
      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end

      within "form#item-form" do
        within "#addon-gws-agents-addons-member" do
          wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
        end
      end
      script = <<~SCRIPT
        Array.from(
          document.querySelectorAll("#ajax-box .list-item[data-id]"),
          (el) => el.dataset.id)
      SCRIPT
      first_page_ids = second_page_ids = nil
      wait_for_event_fired "ss:ajaxPagination" do
        within_cbox do
          first_page_ids = page.evaluate_script(script)
          expect(first_page_ids.length).to eq max_items_per_page
          expect(page).to have_css(".pagination", text: "2")
          within ".pagination" do
            click_on "2"
          end
        end
      end
      within_cbox do
        second_page_ids = page.evaluate_script(script)
        expect(second_page_ids.length).to eq max_items_per_page
      end

      expect(first_page_ids & second_page_ids).to be_empty
    end
  end
end
