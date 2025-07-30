require 'spec_helper'

describe "gws_monitor_topics", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:g3) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:g1_user) { create :gws_user, group_ids: [ g1.id ], gws_role_ids: user.gws_role_ids }
  # let!(:g2_user) { create :gws_user, group_ids: [ g2.id ], gws_role_ids: user.gws_role_ids }
  # let!(:g3_user) { create :gws_user, group_ids: [ g3.id ], gws_role_ids: user.gws_role_ids }
  let!(:file) { tmp_ss_file(contents: '0123456789', user: user) }
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:item1) do
    create(
      :gws_monitor_topic, cur_site: site, cur_user: user, due_date: now + 1.week,
      attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open', spec_config: 'my_group',
      text_type: "plain", text: Array.new(2) { "text-#{unique_id}" }.join("\r\n"),
      file_ids: [ file.id ], answer_state_hash: { g1.id.to_s => "preparation", g2.id.to_s => "preparation" }
    )
  end

  before { login_user g1_user }

  describe "#forward" do
    it do
      visit gws_monitor_topics_path(site: site)
      click_on item1.name
      click_on I18n.t('gws/monitor.links.forward')
      within "form#item-form" do
        within "#addon-gws-agents-addons-monitor-group" do
          wait_for_cbox_opened { click_on I18n.t("ss.apis.groups.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on g3.section_name }
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-monitor-group" do
          expect(page).to have_css("[data-id='#{g3.id}']", text: g3.name)
        end
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Monitor::Topic.all.count).to eq 2
      Gws::Monitor::Topic.all.ne(id: item1.id).first.tap do |new_topic|
        # 基本情報
        expect(new_topic.name).to eq item1.name
        expect(new_topic.spec_config).to eq item1.spec_config
        expect(new_topic.notice_state).to eq item1.notice_state
        expect(new_topic.due_date).to eq item1.due_date
        expect(new_topic.mode).to eq item1.mode
        # 参加グループ
        expect(new_topic.attend_group_ids).to eq [ g3.id ]
        expect(new_topic.attend_group_ids).not_to eq item1.attend_group_ids
        # 投稿者
        expect(new_topic.contributor_model).to eq "Gws::User"
        expect(new_topic.contributor_id).to eq g1_user.id.to_s
        expect(new_topic.contributor_name).to eq g1_user.long_name
        # 内容
        expect(new_topic.text_type).to eq item1.text_type
        expect(new_topic.text).to eq item1.text
        # ファイル
        expect(new_topic.file_ids).not_to eq item1.file_ids
        expect(new_topic.file_ids.length).to eq item1.file_ids.length
        new_topic.files.first.tap do |new_file|
          expect(new_file.id).not_to eq file.id
          expect(new_file.name).to eq file.name
          expect(new_file.filename).to eq file.filename
          expect(new_file.content_type).to eq file.content_type
          expect(new_file.size).to eq file.size
          expect(new_file.owner_item_id).to eq new_topic.id
          expect(new_file.owner_item_type).to eq new_topic.class.name
          expect(new_file.user_id).to eq g1_user.id
          expect(new_file.site_id).to be_blank
        end
        # カテゴリー
        expect(new_topic.state).to eq "draft"
        expect(new_topic.released).to be_blank
        # 管理権限
        expect(new_topic.group_ids).to eq g1_user.group_ids
        expect(new_topic.user_ids).to eq [ g1_user.id ]
        expect(new_topic.group_ids).not_to eq item1.group_ids
        expect(new_topic.user_ids).not_to eq item1.user_ids
      end
    end
  end
end
