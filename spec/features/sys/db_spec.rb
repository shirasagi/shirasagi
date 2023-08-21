require 'spec_helper'

describe "sys_db", type: :feature, dbscope: :example do
  let(:index_path) { sys_db_colls_path }

  it "without auth" do
    visit index_path
    expect(status_code).to eq 200
    expect(page).to have_css(".login-box", text: I18n.t("ss.login"))
  end

  context "with auth" do
    before { login_sys_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path

      within ".index" do
        click_on SS::Sequence.collection_name
      end
      within ".index" do
        within first("tbody tr") do
          click_on I18n.t("ss.links.show")
        end
      end
    end
  end
end
