require 'spec_helper'

describe "rdf_vocabs", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { rdf_vocabs_path site.host }
  let(:new_path) { new_rdf_vocab_path site.host }

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
          fill_in "item[prefix]", with: "p#{unique_id}"
          fill_in "item[uri]", with: "http://example.jp/rdf/#{unique_id}#"
          fill_in "item[labels][ja]", with: "sample-#{unique_id}"
          click_button I18n.t("views.button.save")
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#show" do
      let(:item) { create(:rdf_vocab, site: site) }
      let(:show_path) { rdf_vocab_path site.host, item }

      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end
    end

    describe "#edit" do
      let(:item) { create(:rdf_vocab, site: site) }
      let(:edit_path) { edit_rdf_vocab_path site.host, item }

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
      let(:item) { create(:rdf_vocab, site: site) }
      let(:delete_path) { delete_rdf_vocab_path site.host, item }

      it do
        visit delete_path
        within "form" do
          click_button I18n.t("views.button.delete")
        end
        expect(current_path).to eq index_path
      end
    end

    describe "#import" do
      let(:import_path) { import_rdf_vocabs_path site.host }

      it do
        visit import_path
        within "form#item-form" do
          fill_in "params[prefix]", with: "p#{unique_id}"
          attach_file "params[in_file]", "#{Rails.root}/spec/fixtures/rdf/ipa-core-sample.ttl"
          click_button I18n.t("rdf.vocabs.import")
        end
        expect(current_path).to eq index_path
      end
    end
  end
end
