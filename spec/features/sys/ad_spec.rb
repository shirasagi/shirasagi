require 'spec_helper'

describe "sys_ad", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let!(:user) { sys_user }
    let!(:file1) do
      tmp_ss_file(basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: user)
    end
    let!(:file2) do
      tmp_ss_file(basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: user)
    end
    let(:time1) { rand(5..10) }
    let(:width1) { rand(200..300) }
    let(:time2) { rand(5..10) }
    let(:width2) { rand(200..300) }
    let(:name1) { "name-#{unique_id}" }
    let(:name2) { "name-#{unique_id}" }
    let(:url1) { unique_url }
    let(:url2) { unique_url }

    before { login_sys_user }

    it do
      #
      # New
      #
      login_user user, to: sys_ad_path
      visit sys_ad_path
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[time]", with: time1
        fill_in "item[width]", with: width1

        within "[data-index='new']" do
          fill_in "item[ad_links][][name]", with: name1
          fill_in "item[ad_links][][url]", with: url1
          select I18n.t("ss.options.link_target._blank"), from: "item[ad_links][][target]"
          attach_to_ss_file_field "item[ad_links][][file_id]", file1
          select I18n.t("ss.options.state.show"), from: "item[ad_links][][state]"
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      Sys::Setting.first.tap do |setting|
        expect(setting.time).to eq time1
        expect(setting.width).to eq width1

        setting.ad_links.to_a.tap do |ad_links|
          expect(ad_links).to have(1).items
          ad_links[0].tap do |ad_link|
            expect(ad_link.id).to be_present
            expect(ad_link.name).to eq name1
            expect(ad_link.url).to eq url1
            expect(ad_link.target).to eq "_blank"
            expect(ad_link.file).to be_present
            expect(ad_link.state).to eq "show"

            file = ad_link.file
            expect(file.id).to eq file1.id
            expect(file.model).to eq setting.class.name.underscore
            expect(file.owner_item_type).to eq setting.class.name
            expect(file.owner_item_id.to_s).to eq setting.id.to_s
            expect(file.state).to eq "public"
          end
        end
      end

      #
      # Edit
      #
      visit sys_ad_path
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[time]", with: time2
        fill_in "item[width]", with: width2

        within first("[data-index]") do
          fill_in "item[ad_links][][name]", with: name2
          fill_in "item[ad_links][][url]", with: url2
          select I18n.t("ss.options.link_target._self"), from: "item[ad_links][][target]"
          attach_to_ss_file_field "item[ad_links][][file_id]", file2
          select I18n.t("ss.options.state.hide"), from: "item[ad_links][][state]"
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      Sys::Setting.first.tap do |setting|
        expect(setting.time).to eq time2
        expect(setting.width).to eq width2

        setting.ad_links.to_a.tap do |ad_links|
          expect(ad_links).to have(1).items
          ad_links[0].tap do |ad_link|
            expect(ad_link.id).to be_present
            expect(ad_link.name).to eq name2
            expect(ad_link.url).to eq url2
            expect(ad_link.target).to eq "_self"
            expect(ad_link.file).to be_present
            expect(ad_link.state).to eq "hide"

            file = ad_link.file
            expect(file.id).to eq file2.id
            expect(file.model).to eq setting.class.name.underscore
            expect(file.owner_item_type).to eq setting.class.name
            expect(file.owner_item_id.to_s).to eq setting.id.to_s
            expect(file.state).to eq "public"
          end
        end
      end

      #
      # Delete
      #
      visit sys_ad_path
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[time]", with: ""
        fill_in "item[width]", with: ""

        within first("[data-index]") do
          click_on "remove"
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      Sys::Setting.first.tap do |setting|
        expect(setting.time).to be_blank
        expect(setting.width).to be_blank

        # 全部削除しても、どうしても一つ残ってしまう。
        setting.ad_links.to_a.tap do |ad_links|
          expect(ad_links).to have(1).items

          ad_links[0].tap do |ad_link|
            expect(ad_link.id).to be_present
            expect(ad_link.name).to be_blank
            expect(ad_link.url).to be_blank
            expect(ad_link.target).to eq "_blank"
            expect(ad_link.file).to be_blank
            expect(ad_link.state).to eq "show"
          end
        end
      end
    end
  end
end
