require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example do
  context "comments" do
    let(:site) { gws_site }
    let!(:user1) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user2) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:show_path) { gws_board_topic_path site, '-', '-', topic }
    let(:name) { unique_id }
    let(:text) { unique_id }

    before { login_gws_user }

    context "with thread topic" do
      let(:topic) { create :gws_board_topic, mode: 'thread', readable_member_ids: [ gws_user.id, user1.id, user2.id ] }

      before do
        topic.set_browsed!(gws_user)
        topic.set_browsed!(user1)
        topic.set_browsed!(user2)
      end

      it "#show" do
        topic.reload
        expect(topic.browsed?(gws_user)).to be_truthy
        expect(topic.browsed?(user1)).to be_truthy
        expect(topic.browsed?(user2)).to be_truthy

        visit show_path
        expect(page).to have_css("article.topic .name", text: topic.name)
        expect(page).to have_css("article.topic .body", text: topic.text)

        within "article.topic div.menu" do
          click_on "返信する"
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)

        expect(Gws::Board::Post.where(topic_id: topic.id).count).to eq 1
        comment = Gws::Board::Post.where(topic_id: topic.id).first
        expect(comment.name).to eq name
        expect(comment.text).to eq text

        # コメント投稿者の既読状態は維持される
        topic.reload
        expect(topic.browsed?(gws_user)).to be_truthy
        expect(topic.browsed?(user1)).to be_falsey
        expect(topic.browsed?(user2)).to be_falsey
      end
    end

    context "with tree topic" do
      let(:topic) { create :gws_board_topic, mode: 'tree', readable_member_ids: [ gws_user.id, user1.id, user2.id ] }
      let(:name2) { unique_id }
      let(:text2) { unique_id }

      before do
        topic.set_browsed!(gws_user)
        topic.set_browsed!(user1)
        topic.set_browsed!(user2)
      end

      it "#show" do
        topic.reload
        expect(topic.browsed?(gws_user)).to be_truthy
        expect(topic.browsed?(user1)).to be_truthy
        expect(topic.browsed?(user2)).to be_truthy

        visit show_path
        expect(page).to have_css("article.topic .name", text: topic.name)
        expect(page).to have_css("article.topic .body", text: topic.text)

        within "article.topic div.menu" do
          click_on "返信する"
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)

        expect(Gws::Board::Post.where(topic_id: topic.id).count).to eq 1
        comment = Gws::Board::Post.where(topic_id: topic.id).first
        expect(comment.name).to eq name
        expect(comment.text).to eq text

        # コメント投稿者の既読状態は維持される
        topic.reload
        expect(topic.browsed?(gws_user)).to be_truthy
        expect(topic.browsed?(user1)).to be_falsey
        expect(topic.browsed?(user2)).to be_falsey

        within "aside.comment div.menu" do
          click_on "返信する"
        end

        within "form#item-form" do
          fill_in "item[name]", with: name2
          fill_in "item[text]", with: text2
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)
        expect(page).to have_css("aside.comment h2", text: name2)
        expect(page).to have_css("aside.comment .body", text: text2)

        expect(Gws::Board::Post.where(topic_id: topic.id).count).to eq 2
        comment = Gws::Board::Post.where(topic_id: topic.id).order_by(created: -1).first
        expect(comment.name).to eq name2
        expect(comment.text).to eq text2

        # コメント投稿者の既読状態は維持される
        topic.reload
        expect(topic.browsed?(gws_user)).to be_truthy
        expect(topic.browsed?(user1)).to be_falsey
        expect(topic.browsed?(user2)).to be_falsey
      end
    end
  end
end
