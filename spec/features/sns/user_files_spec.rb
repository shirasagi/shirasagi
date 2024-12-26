require 'spec_helper'

describe "sns_user_files", type: :feature, dbscope: :example, js: true do
  before { login_ss_user }

  context "basic crud" do
    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq "logo.png"
      expect(item.user_id).to eq ss_user.id

      visit sns_cur_user_files_path
      click_on item.name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.name).to eq "modify"

      visit sns_cur_user_files_path
      click_on item.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "when validation error occurred" do
    it do
      visit new_sns_cur_user_file_path
      within "form#item-form" do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_error I18n.t("errors.messages.blank")

      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq "logo.png"
      expect(item.user_id).to eq ss_user.id
    end
  end

  context "with regular svg file" do
    let(:file) do
      tmpfile(extname: ".svg") do |f|
        f.write <<~SVG
          <?xml version="1.0" encoding="utf-8"?>
          <svg xmlns="http://www.w3.org/2000/svg">
            <text x="0" y="0">SHIRASAGI</text>
          </svg>
        SVG
      end
    end
    let(:name) { File.basename(file) }

    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", file
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq name
      expect(item.user_id).to eq ss_user.id

      visit sns_cur_user_files_path
      click_on item.name
      expect(page).to have_content(name)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.name).to eq "modify"

      visit sns_cur_user_files_path
      click_on item.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "sanitize: svg file with inline script" do
    let(:file) do
      tmpfile(extname: ".svg") do |f|
        f.write <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <text x="0" y="0">SHIRASAGI</text>
            <script>alert("xss")</script>
          </svg>
        SVG
      end
    end
    let(:name) { File.basename(file) }

    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", file
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq name
      expect(item.user_id).to eq ss_user.id

      content = File.read(item.path)
      expect(content).not_to include "script"
    end
  end

  context "sanitize: svg file contains onclick" do
    let(:file) do
      tmpfile(extname: ".svg") do |f|
        f.write <<~SVG
          <?xml version="1.0" encoding="utf-8"?>
          <svg xmlns="http://www.w3.org/2000/svg">
            <text x="0" y="0" onclick="alert('xss')">SHIRASAGI</text>
          </svg>
        SVG
      end
    end
    let(:name) { File.basename(file) }

    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", file
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq name
      expect(item.user_id).to eq ss_user.id

      content = File.read(item.path)
      expect(content).not_to include "onclick"
    end
  end

  context "sanitize: svg file with 'javascript' href" do
    let(:file) do
      tmpfile(extname: ".svg") do |f|
        f.write <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <a xlink:href="javascript:alert('xss')"><text x="0" y="0">SHIRASAGI</text></a>
          </svg>
        SVG
      end
    end
    let(:name) { File.basename(file) }

    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", file
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq name
      expect(item.user_id).to eq ss_user.id

      content = File.read(item.path)
      expect(content).not_to include "href"
    end
  end

  context "sanitize: svg file with href to other site" do
    let(:file) do
      tmpfile(extname: ".svg") do |f|
        f.write <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <a xlink:href="https://very.very.danger.com/"><text x="0" y="0">SHIRASAGI</text></a>
          </svg>
        SVG
      end
    end
    let(:name) { File.basename(file) }

    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", file
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq name
      expect(item.user_id).to eq ss_user.id

      content = File.read(item.path)
      expect(content).not_to include "href"
    end
  end

  context "sanitize: svg file with href to myself site" do
    let(:file) do
      tmpfile(extname: ".svg") do |f|
        f.write <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <a xlink:href="/path/to/page.html"><text x="0" y="0">SHIRASAGI</text></a>
          </svg>
        SVG
      end
    end
    let(:name) { File.basename(file) }

    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", file
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq name
      expect(item.user_id).to eq ss_user.id

      content = File.read(item.path)
      expect(content).to include "href"
      expect(content).to include "/path/to/page.html"
    end
  end
end
