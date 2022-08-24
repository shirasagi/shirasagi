require 'spec_helper'

describe "postal_codes", type: :feature, dbscope: :example, js: true do
  let(:item) { create :sys_postal_code }
  let(:index_path) { sys_postal_codes_path }

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
          fill_in "item[code]", with: "code"
          fill_in "item[prefecture]", with: "prefecture"
          fill_in "item[prefecture_kana]", with: "prefecture_kana"
          fill_in "item[prefecture_code]", with: "prefecture_code"
          fill_in "item[city]", with: "city"
          fill_in "item[city_kana]", with: "city_kana"
          fill_in "item[town]", with: "city"
          fill_in "item[town_kana]", with: "town_kana"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Sys::PostalCode.all.count).to eq 1
        item = Sys::PostalCode.all.first
        expect(item.code).to eq "code"

        visit index_path
        click_on item.code
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[code]", with: "modify"
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        item.reload
        expect(item.code).to eq "modify"

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

    context "#download" do
      it do
        visit index_path
        click_on I18n.t("ss.links.download")

        wait_for_download

        expect(History::Log.all.count).to be > 1
        History::Log.all.reorder(created: -1).first.tap do |history|
          expect(history.url).to eq download_sys_postal_codes_path
          expect(history.controller).to eq "sys/postal_codes"
          expect(history.action).to eq "download"
        end
      end
    end

    context "#import" do
      it do
        visit index_path
        click_on I18n.t("ss.links.import")

        within "form" do
          click_button I18n.t('ss.buttons.import')
        end
        expect(page).to have_css("#errorExplanation")

        within "form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/sys/postal_code.csv"
          click_button I18n.t('ss.buttons.import')
        end
        wait_for_notice I18n.t('ss.notice.started_import')

        expect(enqueued_jobs.length).to eq 1
        enqueued_jobs.first.tap do |enqueued_job|
          expect(enqueued_job[:job]).to eq Sys::PostalCode::ImportJob
          expect(enqueued_job[:args]).to have(1).items
          expect(enqueued_job[:at]).to be_blank
        end
      end
    end
  end

  context "with keyword" do
    before { login_sys_user }

    it do
      # ensure that item is created
      item

      visit index_path
      within "form.index-search" do
        fill_in "s[keyword]", with: item.code
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".title", text: item.code)

      visit index_path
      within "form.index-search" do
        fill_in "s[keyword]", with: unique_id
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_css(".title", text: item.code)
    end
  end
end
