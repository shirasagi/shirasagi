require 'spec_helper'

describe "gws_monitor_comments", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:role) do
    create(
      :gws_role, permissions: %w(
        use_gws_monitor read_private_gws_monitor_categories read_private_gws_monitor_posts
        edit_private_gws_monitor_posts delete_private_gws_monitor_posts trash_private_gws_monitor_posts
      )
    )
  end
  let!(:user1) { create(:gws_user, group_ids: [ g1.id ], gws_role_ids: [ role.id ]) }
  let!(:user2) { create(:gws_user, group_ids: [ g2.id ], gws_role_ids: [ role.id ]) }
  let!(:admin) { create(:gws_user, group_ids: [ g1.id ], gws_role_ids: [ create(:gws_role_admin).id ]) }
  let!(:topic) do
    create(
      :gws_monitor_topic, attend_group_ids: [ g1.id, g2.id ], state: 'public', article_state: 'open',
      spec_config: 'my_group', answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end
  let!(:comment) do
    create(:gws_monitor_post, cur_user: user1, user_group_id: g1.id, topic_id: topic.id, parent_id: topic.id)
  end
  let(:name) { "name-#{unique_id}" }

  context "with the user who answered" do
    before { login_user user1 }

    it "#edit" do
      visit gws_monitor_answer_path(site: site, id: topic)
      within "#post-#{comment.id}" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      comment.reload
      expect(comment.name).to eq name
    end

    it "#delete" do
      visit gws_monitor_answer_path(site: site, id: topic)
      within "#post-#{comment.id}" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { comment.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end

    it "#edit via answers" do
      visit edit_gws_monitor_answer_parent_comment_path(site: site, answer_id: topic, parent_id: topic, id: comment)
      expect(status_code).to eq 200
      expect(page).to have_field("item[name]", with: comment.name)
    end

    context "when the comment belongs to another topic" do
      let!(:topic2) do
        create(
          :gws_monitor_topic, attend_group_ids: [ g1.id, g2.id ], state: 'public', article_state: 'open',
          spec_config: 'my_group', answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
        )
      end

      it "#edit" do
        visit edit_gws_monitor_answer_parent_comment_path(site: site, answer_id: topic2, parent_id: topic2, id: comment)
        expect(status_code).to eq 404
      end

      context "when the parent in the url is not the actual parent" do
        let!(:other_parent) do
          create(:gws_monitor_post, cur_user: user2, user_group_id: g2.id, topic_id: topic2.id, parent_id: topic2.id)
        end

        it "#edit and #delete" do
          visit edit_gws_monitor_answer_parent_comment_path(site: site, answer_id: topic, parent_id: other_parent, id: comment)
          expect(status_code).to eq 404
          visit delete_gws_monitor_answer_parent_comment_path(site: site, answer_id: topic, parent_id: other_parent, id: comment)
          expect(status_code).to eq 404

          comment.reload
          expect(comment.parent_id).to eq topic.id
          expect(comment.topic_id).to eq topic.id
        end
      end
    end
  end

  context "with the user who has only use and read_private permissions" do
    let!(:minimum_role) { create(:gws_role, permissions: %w(use_gws_monitor read_private_gws_monitor_posts)) }
    let!(:user3) { create(:gws_user, group_ids: [ g1.id ], gws_role_ids: [ minimum_role.id ]) }
    let!(:topic3) do
      create(
        :gws_monitor_topic, attend_group_ids: [ g1.id, g2.id ], state: 'public', article_state: 'open',
        spec_config: 'my_group', answer_state_hash: { g1.id.to_s => "public", g2.id.to_s => "preparation" }
      )
    end
    let(:answer_name) { "answer-#{unique_id}" }

    before { login_user user3 }

    it "answers, edits and deletes own answer" do
      # 回答する
      visit gws_monitor_topic_path(site: site, id: topic3)
      click_on I18n.t("gws/monitor.links.comment")
      within "form#item-form" do
        fill_in "item[name]", with: answer_name
        click_on I18n.t("gws/monitor.links.comment")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      answer = Gws::Monitor::Post.where(topic_id: topic3.id, name: answer_name).first
      expect(answer).to be_present
      expect(answer.user_ids).to be_blank
      expect(answer.group_ids).to be_blank
      expect(topic3.reload.answer_state_hash[g1.id.to_s]).to eq "answered"

      # 回答済み一覧に出る
      visit gws_monitor_answers_path(site: site)
      click_on topic3.name

      # 編集する
      within "#post-#{answer.id}" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(answer.reload.name).to eq name

      # 削除する
      within "#post-#{answer.id}" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")
      expect { answer.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "with the admin" do
    before { login_user admin }

    it "#edit via admins" do
      visit gws_monitor_admin_path(site: site, id: topic)
      within "#post-#{comment.id}" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      comment.reload
      expect(comment.name).to eq name
    end
  end

  context "with the user in another attended group" do
    before { login_user user2 }

    it "#edit" do
      visit edit_gws_monitor_topic_parent_comment_path(site: site, topic_id: topic, parent_id: topic, id: comment)
      expect(status_code).to eq 403
    end

    it "#delete" do
      visit delete_gws_monitor_topic_parent_comment_path(site: site, topic_id: topic, parent_id: topic, id: comment)
      expect(status_code).to eq 403
    end
  end
end
