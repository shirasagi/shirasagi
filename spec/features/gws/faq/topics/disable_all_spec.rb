require 'spec_helper'

describe "gws_faq_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:cate) { create :gws_faq_category, cur_site: site }
  let!(:topic) { create :gws_faq_topic, cur_site: site, mode: 'thread', category_ids: [ cate.id ] }
  let(:now) { Time.zone.now.change(usec: 0) }

  context "disable (soft delete) all" do
    it do
      login_user user, to: gws_faq_topics_path(site: site, mode: '-', category: '-')
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
      page.accept_confirm(I18n.t("ss.confirm.delete")) do
        within ".list-head-action" do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      topic.reload
      expect(topic.deleted.in_time_zone).to be_within(30.seconds).of(now)

      expect(topic.histories.count).to eq 2
      topic.histories.to_a.tap do |histories|
        histories.first.tap do |history|
          expect(history.name).to eq topic.name
          expect(history.mode).to eq "update"
          expect(history.model).to eq topic.class.model_name.i18n_key.to_s
          expect(history.model_name).to eq I18n.t("mongoid.models.#{topic.class.model_name.i18n_key}")
          expect(history.item_id).to eq topic.id.to_s
          expect(history.path).to be_blank
          expect(history.path).to eq topic.histories.last.path
        end
      end
    end
  end

  context "if user don't have permissions to delete" do
    before do
      user.gws_roles.each do |role|
        permissions = role.permissions.dup
        permissions -= %w(delete_other_gws_faq_posts delete_private_gws_faq_posts)
        role.update!(permissions: permissions)
      end
    end

    it do
      login_user user, to: gws_faq_topics_path(site: site, mode: '-', category: '-')
      expect(page).to have_css(".list-item", text: topic.name)
      expect(page).to have_no_css(".list-head-action")
    end
  end
end
