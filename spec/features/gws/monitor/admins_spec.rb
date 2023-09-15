require 'spec_helper'

describe "gws_monitor_admins", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:file) { tmp_ss_file(contents: '0123456789', user: user) }
  let(:item1) do
    create(
      :gws_monitor_topic, cur_site: site, cur_user: user,
      attend_group_ids: [g1.id, g2.id], state: 'public', article_state: 'open', spec_config: 'my_group',
      file_ids: [ file.id ], answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "preparation" }
    )
  end

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      item1
      visit gws_monitor_admins_path(site)
      expect(page).to have_content(item1.name)
      expect(page).to have_content("#{I18n.t('gws/monitor.topic.answer_state')}(1/2)")
    end

    it "#new" do
      visit new_gws_monitor_admin_path(site)
      expect(page).to have_content(I18n.t("ss.basic_info"))
    end

    it "#copy" do
      item1.reload
      expect(item1.file_ids).to have(1).items
      file.reload
      expect(file.owner_item_id).to eq item1.id
      expect(file.owner_item_type).to eq item1.class.name

      visit gws_monitor_admins_path(site)
      click_on item1.name

      click_on I18n.t("ss.links.copy")
      within "form#item-form" do
        fill_in "item[name]", with: "copy_sample"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(current_path).not_to eq copy_gws_monitor_admin_path(item1.id,site)
      expect(page).to have_content("copy_sample")

      expect(Gws::Monitor::Topic.all.count).to eq 2
      copy_topic = Gws::Monitor::Topic.all.ne(id: item1.id).first
      expect(copy_topic.name).to eq "copy_sample"
      expect(copy_topic.mode).to eq item1.mode
      expect(copy_topic.permit_comment).to eq item1.permit_comment
      expect(copy_topic.descendants_updated).to eq copy_topic.updated
      expect(copy_topic.severity).to eq copy_topic.severity
      expect(copy_topic.due_date).to eq copy_topic.due_date
      expect(copy_topic.spec_config).to eq item1.spec_config
      expect(copy_topic.attend_group_ids).to eq item1.attend_group_ids
      expect(copy_topic.contributor_model).to eq item1.contributor_model
      expect(copy_topic.contributor_id).to eq item1.contributor_id
      expect(copy_topic.contributor_name).to eq item1.contributor_name
      expect(copy_topic.text).to eq item1.text
      expect(copy_topic.text_type).to eq item1.text_type
      expect(copy_topic.file_ids).to have(1).items
      copy_topic.files.first.tap do |copy_file|
        expect(copy_file.id).not_to eq file.id
        expect(copy_file.owner_item_id).to eq copy_topic.id
        expect(copy_file.owner_item_type).to eq copy_topic.class.name
      end
      expect(copy_topic.category_ids).to eq item1.category_ids
      expect(copy_topic.state).to eq "draft"
      expect(copy_topic.released).to eq item1.released
      expect(copy_topic.release_date).to eq item1.release_date
      expect(copy_topic.close_date).to eq item1.close_date
      expect(copy_topic.group_ids).to eq item1.group_ids
      copy_topic.attend_group_ids.each do |group_id|
        expect(copy_topic.answer_state_hash[group_id.to_s]).to eq "preparation"
      end
      expect(copy_topic.answer_state_hash.keys.sort).to eq copy_topic.attend_group_ids.map(&:to_s).sort
      expect(copy_topic.answer_state_hash.values.all?("preparation")).to be_truthy
      expect(copy_topic.notice_state).to eq item1.notice_state
      expect(copy_topic.notice_at).to be_blank

      # fileの所有者に変化がないことを確認する
      file.reload
      expect(file.owner_item_id).to eq item1.id
      expect(file.owner_item_type).to eq item1.class.name
    end
  end
end
