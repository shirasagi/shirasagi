require 'spec_helper'

describe "gws_monitor_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:r1) { create(:gws_role_admin) }
  let(:u1) { create(:gws_user, group_ids: [g1.id], gws_role_ids: [r1.id]) }

  before { login_user u1 }

  describe "#print" do
    context "with thread" do
      let!(:item) do
        create(
          :gws_monitor_topic, attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open', mode: 'thread'
        )
      end

      it do
        visit gws_monitor_topics_path(site)
        click_on item.name
        click_on I18n.t("ss.links.print")

        within ".print-preview.vertical" do
          expect(page).to have_css(".name", text: item.name)
        end
      end
    end

    context "with tree" do
      let!(:item) do
        create(
          :gws_monitor_topic, attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open', mode: 'tree'
        )
      end

      it do
        visit gws_monitor_topics_path(site)
        click_on item.name
        click_on I18n.t("ss.links.print")

        within ".print-preview.vertical" do
          expect(page).to have_css(".name", text: item.name)
        end
      end
    end
  end
end
