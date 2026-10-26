require 'spec_helper'

describe "gws_faq_topics", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:role) do
    create(
      :gws_role, permissions: %w(
        use_gws_faq read_private_gws_faq_categories read_private_gws_faq_posts
        edit_private_gws_faq_posts delete_private_gws_faq_posts trash_private_gws_faq_posts
      )
    )
  end
  let!(:user1) { create(:gws_user, group_ids: [ g1.id ], gws_role_ids: [ role.id ]) }
  let!(:category) { create :gws_faq_category }
  let!(:item) { create :gws_faq_topic, category_ids: [ category.id ], readable_setting_range: 'public' }
  let!(:closed_item) do
    create :gws_faq_topic, category_ids: [ category.id ], readable_setting_range: 'select',
      readable_group_ids: gws_user.group_ids
  end
  let!(:selected_item) do
    create :gws_faq_topic, category_ids: [ category.id ], readable_setting_range: 'select',
      readable_group_ids: [ g1.id ]
  end
  let(:name) { "name-#{unique_id}" }

  before { login_user user1 }

  context "with the topic readable by the user" do
    it "#show, #read and #unread" do
      visit gws_faq_topics_path(site: site, mode: '-', category: '-')
      click_on item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".topic .name", text: item.name)

      click_on I18n.t('gws/faq.topic.set_browsed')
      expect(status_code).to eq 200
      expect(item.reload.browsed?(user1)).to be_truthy

      click_on I18n.t('gws/faq.topic.unset_browsed')
      expect(status_code).to eq 200
      expect(item.reload.browsed?(user1)).to be_falsey
    end
  end

  context "with the topic readable by the user's group" do
    it "#show" do
      visit gws_faq_topics_path(site: site, mode: '-', category: '-')
      click_on selected_item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".topic .name", text: selected_item.name)
    end
  end

  context "with the user who can edit only own group's topics" do
    it "#edit, #update, #delete and #destroy" do
      # 閲覧設定で公開されただけの FAQ は編集・削除できない（取得範囲は allow(:read) のまま）
      visit edit_gws_faq_topic_path(site: site, mode: '-', category: '-', id: item)
      expect(status_code).to eq 404

      visit delete_gws_faq_topic_path(site: site, mode: '-', category: '-', id: item)
      expect(status_code).to eq 404

      # group_ids を自分のグループに書き換えて送っても、所有者を奪えない
      page.driver.put gws_faq_topic_path(site: site, mode: '-', category: '-', id: item),
        item: { name: name, group_ids: [ g1.id ] }
      expect(status_code).to eq 404

      item.reload
      expect(item.name).not_to eq name
      expect(item.group_ids).not_to include(g1.id)

      page.driver.delete gws_faq_topic_path(site: site, mode: '-', category: '-', id: item)
      expect { item.reload }.not_to raise_error
      expect(item.deleted).to be_blank
    end
  end

  context "with the user who has no read permission" do
    let!(:role) { create(:gws_role, permissions: %w(use_gws_faq)) }

    it "#show" do
      visit gws_faq_topic_path(site: site, mode: '-', category: '-', id: item)
      expect(status_code).to eq 404
    end
  end

  context "with the topic not readable by the user" do
    it "#show" do
      visit gws_faq_topics_path(site: site, mode: '-', category: '-')
      expect(page).to have_no_link(closed_item.name)

      visit gws_faq_topic_path(site: site, mode: '-', category: '-', id: closed_item)
      expect(status_code).to eq 404
    end
  end
end
