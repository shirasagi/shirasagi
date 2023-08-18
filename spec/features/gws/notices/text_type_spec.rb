require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:cate) { create :gws_notice_category, cur_site: site }
  let!(:folder) { create :gws_notice_folder, cur_site: site }

  before { login_gws_user }

  context "with plain" do
    let(:name) { unique_id }
    let(:text_type) { "plain" }
    let(:text_type_label) { I18n.t("ss.options.text_type.#{text_type}") }
    let(:texts) { Array.new(2) { unique_id } }

    it do
      visit gws_notice_editables_path(site: site, folder_id: folder, category_id: "-")
      expect(page).to have_css("#content-navi", text: "refresh")

      click_on I18n.t("ss.links.new")
      within "#item-form" do
        fill_in "item[name]", with: name
        select text_type_label, from: "item[text_type]"
        fill_in "item[text]", with: texts.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.site(site).first.tap do |post|
        expect(post.name).to eq name
        expect(post.text_type).to eq text_type
        expect(post.text).to eq texts.join("\r\n")
        expect(post.html).to eq texts.join("<br />")
      end
    end
  end

  context "with markdown" do
    let(:name) { unique_id }
    let(:text_type) { "markdown" }
    let(:text_type_label) { I18n.t("ss.options.text_type.#{text_type}") }
    let(:texts) { Array.new(2) { unique_id } }

    it do
      visit gws_notice_editables_path(site: site, folder_id: folder, category_id: "-")
      expect(page).to have_css("#content-navi", text: "refresh")

      click_on I18n.t("ss.links.new")
      within "#item-form" do
        fill_in "item[name]", with: name
        select text_type_label, from: "item[text_type]"
        fill_in "item[text]", with: texts.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.site(site).first.tap do |post|
        expect(post.name).to eq name
        expect(post.text_type).to eq text_type
        expect(post.text).to eq texts.join("\r\n")
        expect(post.html).to eq "<p>" + texts.join("<br>\n") + "</p>\n"
      end
    end
  end

  context "with cke" do
    let(:name) { unique_id }
    let(:text_type) { "cke" }
    let(:text_type_label) { I18n.t("ss.options.text_type.#{text_type}") }
    let(:texts) { Array.new(2) { unique_id } }

    it do
      visit gws_notice_editables_path(site: site, folder_id: folder, category_id: "-")
      expect(page).to have_css("#content-navi", text: "refresh")

      click_on I18n.t("ss.links.new")
      within "#item-form" do
        fill_in "item[name]", with: name
        wait_event_to_fire("ss:editorActivated") do
          select text_type_label, from: "item[text_type]"
        end
        fill_in_ckeditor "item[text]", with: texts.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.site(site).first.tap do |post|
        expect(post.name).to eq name
        expect(post.text_type).to eq text_type
        expect(post.text).to eq "<p>" + texts.join(" ") + "</p>"
        expect(post.html).to eq "<div class=\"ss-cke\"><p>" + texts.join(" ") + "</p></div>"
      end
    end
  end

  context "xss: plain to markdown" do
    let(:name) { unique_id }
    let(:script) { "<script>alert('xss');</script>" }

    it do
      visit gws_notice_editables_path(site: site, folder_id: folder, category_id: "-")
      expect(page).to have_css("#content-navi", text: "refresh")

      click_on I18n.t("ss.links.new")
      within "#item-form" do
        fill_in "item[name]", with: name
        # script を設定してから Markdown へ切り替えてみる。
        select I18n.t("ss.options.text_type.plain"), from: "item[text_type]"
        fill_in "item[text]", with: script

        select I18n.t("ss.options.text_type.markdown"), from: "item[text_type]"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.site(site).first.tap do |post|
        expect(post.name).to eq name
        expect(post.text_type).to eq "markdown"
        expect(post.text).to eq script
        expect(post.html).to eq "alert('xss');\n\n"
      end
    end
  end

  context "xss with plain" do
    let(:name) { unique_id }
    let(:script) { "<script>alert('xss');</script>" }

    it do
      visit gws_notice_editables_path(site: site, folder_id: folder, category_id: "-")
      expect(page).to have_css("#content-navi", text: "refresh")

      click_on I18n.t("ss.links.new")
      within "#item-form" do
        fill_in "item[name]", with: name
        # script を設定してみる
        select I18n.t("ss.options.text_type.plain"), from: "item[text_type]"
        fill_in "item[text]", with: script

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.site(site).first.tap do |post|
        expect(post.name).to eq name
        expect(post.text_type).to eq "plain"
        expect(post.text).to eq script
        expect(post.html).to eq "&lt;script&gt;alert(&#39;xss&#39;);&lt;/script&gt;"
      end
    end
  end

  context "xss: plain to cke" do
    let(:name) { unique_id }
    let(:script) { "<script>alert('xss');</script>" }

    it do
      visit gws_notice_editables_path(site: site, folder_id: folder, category_id: "-")
      expect(page).to have_css("#content-navi", text: "refresh")

      click_on I18n.t("ss.links.new")
      within "#item-form" do
        fill_in "item[name]", with: name
        # script を設定してから CKEditor へ切り替えてみる。
        select I18n.t("ss.options.text_type.plain"), from: "item[text_type]"
        fill_in "item[text]", with: script

        wait_event_to_fire("ss:editorActivated") do
          select I18n.t("ss.options.text_type.cke"), from: "item[text_type]"
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.site(site).first.tap do |post|
        expect(post.name).to eq name
        expect(post.text_type).to eq "cke"
        expect(post.text).to be_blank
        expect(post.html).to be_blank
      end
    end
  end
end
