
require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }

  before do
    @save_tag = SS.config.cms.tag
    SS.config.replace_value_at(:cms, :tag, true)

    login_cms_user
  end

  after do
    SS.config.replace_value_at(:cms, :tag, @save_tag)
  end

  context "tags with node" do
    let(:tags) { Array.new(3) { unique_id } }

    it do
      visit cms_node_path(site: site, id: node)
      expect(page).to have_css("#addon-cms-agents-addons-tag_setting", text: I18n.t("modules.addons.cms/tag_setting"))

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        ensure_addon_opened("#addon-cms-agents-addons-tag_setting")
        within "#addon-cms-agents-addons-tag_setting" do
          fill_in "item[st_tags]", with: tags.join(" ")
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Node.find(node.id).tap do |new_node|
        expect(new_node.st_tags).to eq tags
      end
    end
  end

  context "tags with page" do
    let(:st_tags) { Array.new(3) { unique_id } }
    let(:name) { unique_id }
    let(:body) { "<p>#{unique_id}</p>" }
    let(:tags) { st_tags.sample(rand(1..2)) }

    before do
      node.update!(st_tags: st_tags)
    end

    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in_ckeditor "item[html]", with: body

        ensure_addon_opened("#addon-cms-agents-addons-tag")
        within "#addon-cms-agents-addons-tag" do
          fill_in "item[tags]", with: tags.join(" ")
        end

        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      expect(Article::Page.all.count).to eq 1
      Article::Page.all.first.tap do |item|
        expect(item.site_id).to eq site.id
        expect(item.name).to eq name
        expect(item.tags).to eq tags
      end
    end
  end

  context "tags with bulk operations" do
    let!(:item1) { create :article_page, cur_site: site, cur_node: node }
    let!(:item2) { create :article_page, cur_site: site, cur_node: node }
    let!(:item3) { create :article_page, cur_site: site, cur_node: node }
    let(:st_tags) { Array.new(3) { unique_id } }
    let(:tag1) { st_tags[0] }
    let(:tag2) { st_tags[1] }
    let(:tag3) { st_tags[2] }

    before do
      node.update!(st_tags: st_tags)
    end

    it do
      visit article_pages_path(site: site, cid: node)
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action-tag" do
        select tag2, from: "tag"
        page.accept_confirm(I18n.t("ss.confirm.set_tag")) do
          click_on I18n.t("ss.links.set_tag")
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item1.reload
      expect(item1.tags).to include(tag2)
      item2.reload
      expect(item2.tags).to include(tag2)
      item3.reload
      expect(item3.tags).to include(tag2)

      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action-tag" do
        select tag1, from: "tag"
        page.accept_confirm(I18n.t("ss.confirm.set_tag")) do
          click_on I18n.t("ss.links.set_tag")
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item1.reload
      expect(item1.tags).to include(tag1, tag2)
      item2.reload
      expect(item2.tags).to include(tag1, tag2)
      item3.reload
      expect(item3.tags).to include(tag1, tag2)

      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      within ".list-head-action-tag" do
        select tag2, from: "tag"
        page.accept_confirm(I18n.t("ss.confirm.reset_tag")) do
          click_on I18n.t("ss.links.reset_tags")
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item1.reload
      expect(item1.tags).to include(tag1)
      expect(item1.tags).not_to include(tag2)
      item2.reload
      expect(item2.tags).to include(tag1)
      expect(item2.tags).not_to include(tag2)
      item3.reload
      expect(item3.tags).to include(tag1)
      expect(item3.tags).not_to include(tag2)
    end
  end
end
