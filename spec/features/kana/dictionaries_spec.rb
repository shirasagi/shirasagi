require 'spec_helper'

describe "kana_dictionaries", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let(:index_path) { kana_dictionaries_path site.id }
  let(:new_path) { new_kana_dictionary_path site.id }
  let(:build_path) { kana_dictionaries_build_path site.id }
  let(:build_confirmation_path) { kana_dictionaries_build_confirmation_path site.id }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[body]", with: "sample, サンプル"
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    context "with item" do
      let!(:item) { create(:kana_dictionary) }
      let(:show_path) { kana_dictionary_path site.id, item }
      let(:edit_path) { edit_kana_dictionary_path site.id, item }
      let(:delete_path) { delete_kana_dictionary_path site.id, item }

      before do
        @save_config = SS.config.replace_value_at(:kana, :build_kana_dictionary_job, { 'perform' => 'now' })
      end

      after do
        SS.config.replace_value_at(:kana, :build_kana_dictionary_job, @save_config)
      end

      it "#show" do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end

      it "#edit" do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_no_css("form#item-form")
      end

      it "#delete" do
        visit delete_path
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end

      describe "#build", mecab: true do
        it "will be success" do
          visit build_confirmation_path
          expect(status_code).to eq 200
          expect(current_path).to eq build_confirmation_path

          within("footer.send") do
            click_button I18n.t("kana.buttons.build_kana_dictionary")
            expect(status_code).to eq 200
            expect(current_path).to eq index_path
          end

          expect(Job::Log.count).to eq 0
        end
      end
    end

    context "without item" do
      let(:missing_item) { 10_000 + rand(10_000) }
      let(:show_path) { kana_dictionary_path site.id, missing_item }
      let(:edit_path) { edit_kana_dictionary_path site.id, missing_item }
      let(:delete_path) { delete_kana_dictionary_path site.id, missing_item }

      before do
        @save_config = SS.config.replace_value_at(:kana, :build_kana_dictionary_job, { 'perform' => 'now' })
      end

      after do
        SS.config.replace_value_at(:kana, :build_kana_dictionary_job, @save_config)
      end

      it "#show" do
        visit show_path
        expect(page).to have_title("404")
      end

      it "#edit" do
        visit edit_path
        expect(page).to have_title("404")
      end

      it "#delete" do
        visit delete_path
        expect(page).to have_title("404")
      end

      describe "#build", mecab: true do
        it "will be bad request" do
          visit build_confirmation_path
          expect(status_code).to eq 200
          expect(current_path).to eq build_confirmation_path

          within("footer.send") do
            click_button I18n.t("kana.buttons.build_kana_dictionary")
            expect(status_code).to eq 400
            expect(current_path).to eq build_path
          end

          expect(Job::Log.count).to eq 0
        end
      end
    end

    context "with build_kana_dictionary_job perform_later" do
      let(:missing_item) { 10_000 + rand(10_000) }
      let(:show_path) { kana_dictionary_path site.id, missing_item }
      let(:edit_path) { edit_kana_dictionary_path site.id, missing_item }
      let(:delete_path) { delete_kana_dictionary_path site.id, missing_item }

      before do
        @save_config = SS.config.replace_value_at(:kana, :build_kana_dictionary_job, { 'perform' => 'later' })
      end

      after do
        SS.config.replace_value_at(:kana, :build_kana_dictionary_job, @save_config)
      end

      it "#show" do
        visit show_path
        expect(page).to have_title("404")
      end

      it "#edit" do
        visit edit_path
        expect(page).to have_title("404")
      end

      it "#delete" do
        visit delete_path
        expect(page).to have_title("404")
      end

      describe "#build", mecab: true do
        it "will be bad request" do
          visit build_confirmation_path
          expect(status_code).to eq 200
          expect(current_path).to eq build_confirmation_path

          within("footer.send") do
            click_button I18n.t("kana.buttons.build_kana_dictionary")
            expect(status_code).to eq 200
            expect(current_path).to eq index_path
          end

          expect(Job::Log.count).to eq 1
          log = Job::Log.first
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end
  end
end
