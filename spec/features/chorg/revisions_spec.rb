require 'spec_helper'

describe "chorg_revisions", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { chorg_revisions_path site.id }
  let(:new_path) { new_chorg_revision_path site.id }

  describe "#index" do
    context "no items" do
      it do
        login_cms_user
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_no_selector("ul.list-items li.list-item nav.tap-menu")
      end
    end

    context "with item" do
      let(:revision) { create(:revision, site_id: site.id) }
      it do
        # ensure that entities has existed.
        expect(revision).not_to be_nil

        login_cms_user
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_selector("ul.list-items li.list-item nav.tap-menu")
      end
    end
  end

  describe "#index" do
    context "when creates new item" do
      it do
        login_cms_user
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(page).to have_no_selector("div#errorExplanation")
        expect(Chorg::Revision.count).to be > 0
      end
    end

    context "when creates same named item" do
      let(:revision) { create(:revision, site_id: site.id) }

      it do
        # ensure that entities has existed.
        expect(revision).not_to be_nil

        login_cms_user
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: revision.name
          click_button I18n.t('ss.buttons.save')
        end

        expect(status_code).to eq 200
        expect(page).to have_selector("div#errorExplanation")
        expect(Chorg::Revision.count).to be > 0
      end
    end
  end
end
