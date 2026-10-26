require 'spec_helper'

describe "gws_qna_topics", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:role) do
    create(
      :gws_role, permissions: %w(
        use_gws_qna read_private_gws_qna_categories read_private_gws_qna_posts
        edit_private_gws_qna_posts delete_private_gws_qna_posts trash_private_gws_qna_posts
      )
    )
  end
  let!(:user1) { create(:gws_user, group_ids: [ g1.id ], gws_role_ids: [ role.id ]) }
  let!(:category) { create :gws_qna_category }
  let!(:item) { create :gws_qna_topic, category_ids: [ category.id ], readable_setting_range: 'public' }
  let!(:closed_item) do
    create :gws_qna_topic, category_ids: [ category.id ], readable_setting_range: 'select',
      readable_group_ids: gws_user.group_ids
  end

  before { login_user user1 }

  context "with the topic readable by the user" do
    it "#show, #read and #unread" do
      visit gws_qna_topics_path(site: site, mode: '-', category: '-')
      click_on item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".topic .name", text: item.name)

      click_on I18n.t('gws/qna.topic.set_browsed')
      expect(status_code).to eq 200
      expect(item.reload.browsed?(user1)).to be_truthy

      click_on I18n.t('gws/qna.topic.unset_browsed')
      expect(status_code).to eq 200
      expect(item.reload.browsed?(user1)).to be_falsey
    end
  end

  context "with the topic not readable by the user" do
    it "#show" do
      visit gws_qna_topics_path(site: site, mode: '-', category: '-')
      expect(page).to have_no_link(closed_item.name)

      visit gws_qna_topic_path(site: site, mode: '-', category: '-', id: closed_item)
      expect(status_code).to eq 404
    end
  end
end
