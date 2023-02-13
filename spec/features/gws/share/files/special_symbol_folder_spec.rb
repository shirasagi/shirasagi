require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  shared_examples "when folder with special symbols is given" do
    let!(:folder) { create :gws_share_folder, cur_site: site, name: "#{unique_id}#{symbols}" }

    before { login_gws_user }

    it do
      visit gws_share_files_path(site)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
      within "#gws-share-file-folder-list" do
        click_on folder.name
      end
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      within "#gws-share-file-folder-list" do
        expect(page).to have_link(folder.name)
      end
      within "#gws-share-file-folder-property" do
        expect(page).to have_css(".folder-name", text: folder.name)
      end
    end
  end

  context "with special symbols in regex" do
    context "with []" do
      let(:symbols) { '[]' }
      it_behaves_like "when folder with special symbols is given"
    end

    context "with ()" do
      let(:symbols) { '()' }
      it_behaves_like "when folder with special symbols is given"
    end

    context "with a$" do
      let(:symbols) { 'a$' }
      it_behaves_like "when folder with special symbols is given"
    end

    context "with '" do
      let(:symbols) { "'" }
      it_behaves_like "when folder with special symbols is given"
    end

    context "with .+" do
      let(:symbols) { '.+' }
      it_behaves_like "when folder with special symbols is given"
    end
  end
end
