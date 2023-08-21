require 'spec_helper'

describe "gws_roles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_role }
  let(:index_path) { gws_roles_path site }

  before { login_gws_user }

  context "crud" do
    it_behaves_like 'crud flow'
  end

  context "download all" do
    it do
      visit index_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.download")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end

      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(StringIO.new(page.html)) do |csv|
          table = csv.read
          expect(table.length).to be > 1
          expect(table.headers).to include(Gws::Role.t(:name), Gws::Role.t(:permissions))
        end
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).first.tap do |history|
        expect(history.severity).to eq "info"
        expect(history.controller).to eq "gws/roles"
        expect(history.path).to eq download_all_gws_roles_path(site: site)
        expect(history.action).to eq "download_all"
      end
    end
  end
end
