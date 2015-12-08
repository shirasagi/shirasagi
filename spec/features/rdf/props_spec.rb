require 'spec_helper'

describe "rdf_props", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:category) { create(:opendata_node_category, cur_site: site) }
  let(:vocab) { create(:rdf_vocab, site: site) }
  let(:index_path) { rdf_props_props_path site.host, vocab.id }
  let(:new_path) { new_rdf_props_prop_path site.host, vocab.id }

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

    context "without class" do
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
        let(:item) { create(:rdf_prop, vocab: vocab) }
        let(:show_path) { rdf_props_prop_path site.host, vocab.id, item }

        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).to eq show_path
        end
      end

      describe "#edit" do
        let(:item) { create(:rdf_prop, vocab: vocab) }
        let(:edit_path) { edit_rdf_props_prop_path site.host, vocab.id, item }

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
        let(:item) { create(:rdf_prop, vocab: vocab) }
        let(:delete_path) { delete_rdf_props_prop_path site.host, vocab.id, item }

        it do
          visit delete_path
          within "form" do
            click_button I18n.t("views.button.delete")
          end
          expect(current_path).to eq index_path
        end
      end
    end

    context "with class" do
      let(:rdf_class) { create(:rdf_class, vocab: vocab) }
      let(:index_path) { rdf_classes_props_props_path site.host, vocab.id, rdf_class.id }
      let(:new_path) { new_rdf_classes_props_prop_path site.host, vocab.id, rdf_class.id }

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
        let(:item) { create(:rdf_prop, vocab: vocab, rdf_class: rdf_class) }
        let(:show_path) { rdf_classes_props_prop_path site.host, vocab.id, rdf_class.id, item }

        it do
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).to eq show_path
        end
      end

      describe "#edit" do
        let(:item) { create(:rdf_prop, vocab: vocab, rdf_class: rdf_class) }
        let(:edit_path) { edit_rdf_classes_props_prop_path site.host, vocab.id, rdf_class.id, item }

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

      describe "#unlink" do
        let(:item) { create(:rdf_prop, vocab: vocab, rdf_class: rdf_class) }
        let(:unlink_path) { unlink_rdf_classes_props_prop_path site.host, vocab.id, rdf_class.id, item }

        it do
          visit unlink_path
          within "form" do
            click_button I18n.t("views.button.delete")
          end
          expect(current_path).to eq index_path
          within "table.index" do
            expect(page).not_to have_text(item.name)
          end
        end
      end

      describe "#import" do
        let!(:item) { create(:rdf_prop, vocab: vocab) }
        let(:import_path) { import_rdf_classes_props_props_path site.host, vocab.id, rdf_class.id }

        it do
          visit import_path
          within "form#item-form" do
            check "item_ids_#{item.id}"
            click_button I18n.t("rdf.button.import")
          end
          expect(current_path).to eq index_path
          within "table.index" do
            expect(page).to have_text(item.name)
          end
        end
      end
    end
  end
end
