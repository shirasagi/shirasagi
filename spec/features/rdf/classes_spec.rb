require 'spec_helper'

describe "rdf_classes", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:category) { create(:opendata_node_category, cur_site: site) }
  let(:vocab) { create(:rdf_vocab, site: site) }
  let(:index_path) { rdf_classes_classes_path site, vocab.id }
  let(:new_path) { new_rdf_classes_class_path site, vocab.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(current_path).to eq index_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "#{unique_id}"
          fill_in "item[labels][ja]", with: "#{unique_id}"
          click_button I18n.t("views.button.save")
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#show" do
      let(:item) { create(:rdf_class, vocab: vocab) }
      let(:show_path) { rdf_classes_class_path site, vocab.id, item }

      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end
    end

    describe "#edit" do
      let(:item) { create(:rdf_class, vocab: vocab) }
      let(:edit_path) { edit_rdf_classes_class_path site, vocab.id, item }

      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[labels][ja]", with: "modify"
          click_button I18n.t("views.button.save")
        end
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#delete" do
      let(:item) { create(:rdf_class, vocab: vocab) }
      let(:delete_path) { delete_rdf_classes_class_path site, vocab.id, item }

      it do
        visit delete_path
        within "form" do
          click_button I18n.t("views.button.delete")
        end
        expect(current_path).to eq index_path
      end
    end
  end

  context "edit subclass", js: true do
    let!(:rdf_class1) { create(:rdf_class, vocab: vocab) }
    let!(:rdf_class2) { create(:rdf_class, vocab: vocab) }
    let(:item) { create(:rdf_class, vocab: vocab) }
    let(:edit_path) { edit_rdf_classes_class_path site, vocab.id, item }

    before { login_cms_user }

    it do
      visit edit_path

      # click ajax link
      within "form#item-form" do
        click_link "継承を変更する"
      end

      wait_for_cbox

      # select rdf class
      within "table.rdf-search-classes-class-list" do
        click_link rdf_class1.preferred_label
      end

      within "form#item-form" do
        click_button I18n.t("views.button.save")
      end

      item.reload
      expect(item.sub_class_id).to eq rdf_class1.id
    end
  end
end
