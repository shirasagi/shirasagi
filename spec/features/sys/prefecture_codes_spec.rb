require 'spec_helper'

describe "prefecture_codes", type: :feature, dbscope: :example, js: true do
  let(:item) { create :sys_prefecture_code }
  let(:index_path) { sys_prefecture_codes_path }
  # let(:new_path) { new_sys_prefecture_code_path }
  # let(:show_path) { sys_prefecture_codes_path item }
  # let(:edit_path) { edit_sys_prefecture_code_path item }
  # let(:delete_path) { delete_sys_prefecture_code_path item }
  # let(:download_path) { download_sys_prefecture_codes_path }
  # let(:import_path) { import_sys_prefecture_codes_path }
  let(:code) do
    c = Array.new(5) { rand(0..9) }.join
    c + Sys::PrefectureCode.check_digit(c)
  end

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(page).to have_css("title", text: "403 Forbidden")
  end

  context "with auth" do
    before { login_sys_user }

    context "basic crud" do
      it do
        visit index_path
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          fill_in "item[code]", with: code
          fill_in "item[prefecture]", with: "prefecture"
          fill_in "item[prefecture_kana]", with: "prefecture_kana"
          fill_in "item[city]", with: "city"
          fill_in "item[city_kana]", with: "city_kana"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Sys::PrefectureCode.all.count).to eq 1
        item = Sys::PrefectureCode.all.first
        expect(item.code).to eq code
        expect(item.prefecture).to eq "prefecture"

        visit index_path
        click_on item.code
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[prefecture]", with: "modify"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload
        expect(item.prefecture).to eq "modify"

        visit index_path
        click_on item.code
        click_on I18n.t("ss.links.delete")
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        wait_for_notice I18n.t("ss.notice.deleted")

        expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end

    describe "#download" do
      it do
        visit index_path
        click_on I18n.t("ss.links.download")

        wait_for_download

        expect(History::Log.all.count).to be > 1
        History::Log.all.reorder(created: -1).first.tap do |history|
          expect(history.url).to eq download_sys_prefecture_codes_path
          expect(history.controller).to eq "sys/prefecture_codes"
          expect(history.action).to eq "download"
        end
      end
    end

    describe "#import" do
      it do
        visit index_path
        click_on I18n.t("ss.links.import")

        within "form" do
          click_button I18n.t('ss.buttons.import')
        end
        expect(page).to have_css("#errorExplanation")

        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/sys/prefecture_code.csv"
          click_button I18n.t('ss.buttons.import')
        end
        wait_for_notice I18n.t('ss.notice.started_import')

        expect(enqueued_jobs.length).to eq 1
        enqueued_jobs.first.tap do |enqueued_job|
          expect(enqueued_job[:job]).to eq Sys::PrefectureCode::ImportJob
          expect(enqueued_job[:args]).to have(1).items
          expect(enqueued_job[:at]).to be_blank
        end
      end
    end

    describe "#search" do
      it do
        # ensure that item is created
        item

        visit index_path
        within "form.index-search" do
          fill_in "s[keyword]", with: item.code
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".title", text: item.code)
        end

        within "form.index-search" do
          fill_in "s[keyword]", with: item.prefecture
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".title", text: item.code)
        end

        within "form.index-search" do
          fill_in "s[keyword]", with: unique_id
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_no_css(".title")
        end
      end
    end
  end
end
