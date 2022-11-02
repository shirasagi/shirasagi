require 'spec_helper'

describe "gws_workload_graph_user_settings", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:index_path) { gws_workload_graph_user_settings_path site }
  let(:name) { user.name }

  context "with auth" do
    before { login_gws_user }

    context "aggregation group not exists" do
      it do
        visit index_path
        within ".list-items" do
          expect(page).to have_no_css(".list-item")
        end
      end
    end

    context "aggregation group created" do
      before do
        Gws::Aggregation::GroupJob.bind(site_id: site.id).perform_now
      end

      it do
        visit index_path
        within ".list-items" do
          click_on name
        end
        within "#addon-basic" do
          expect(page).to have_css("dd", text: name)
        end
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          select I18n.t("ss.options.state.hide"), from: "item[graph_state]"
          fill_in "item[color]", with: "#000000"
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        within "#addon-gws-agents-addons-workload-graph" do
          expect(page).to have_css("dd", text: I18n.t("ss.options.state.hide"))
        end
      end
    end
  end
end
