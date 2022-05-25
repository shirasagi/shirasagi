require 'spec_helper'

describe "cms_nodes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:name) { "name-#{unique_id}" }
  let(:basename) { "basename-#{unique_id}" }

  before { login_cms_user }

  context "basic crud" do
    it do
      visit cms_nodes_path(site: site)
      click_on I18n.t("ss.links.new")

      within "#item-form" do
        within "#addon-basic" do
          wait_cbox_open do
            click_on I18n.t("ss.links.change")
          end
        end
      end
      wait_for_cbox do
        within ".mod-article" do
          click_on I18n.t("cms.nodes.article/page")
        end
      end

      within "#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[basename]", with: basename

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Article::Node::Page.all.count).to eq 1
      Article::Node::Page.all.first.tap do |node|
        expect(node.site_id).to eq site.id
        expect(node.name).to eq name
        expect(node.filename).to eq basename
        expect(node.state).to eq "public"
        expect(node.released_type).to eq "fixed"
        expect(node.released).to be_present
        expect(node.group_ids).to be_present
      end
    end
  end

  context "with form" do
    let!(:form) { create :cms_form, cur_site: site }

    it do
      visit cms_nodes_path(site: site)
      click_on I18n.t("ss.links.new")

      within "#item-form" do
        within "#addon-basic" do
          wait_cbox_open do
            click_on I18n.t("ss.links.change")
          end
        end
      end

      wait_for_cbox do
        within ".mod-article" do
          click_on I18n.t("cms.nodes.article/page")
        end
      end

      within "#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[basename]", with: basename

        within "#addon-cms-agents-addons-form-node" do
          wait_cbox_open do
            click_on I18n.t("cms.apis.forms.index")
          end
        end
      end

      wait_for_cbox do
        wait_cbox_close do
          click_on form.name
        end
      end

      within "#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Article::Node::Page.all.count).to eq 1
      Article::Node::Page.all.first.tap do |node|
        expect(node.site_id).to eq site.id
        expect(node.name).to eq name
        expect(node.filename).to eq basename
        expect(node.st_form_ids).to have(1).items
        expect(node.st_form_ids).to include(form.id)
        expect(node.state).to eq "public"
        expect(node.released_type).to eq "fixed"
        expect(node.released).to be_present
        expect(node.group_ids).to be_present
      end
    end
  end
end
