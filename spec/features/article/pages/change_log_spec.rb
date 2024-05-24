require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }
  let(:show_path) { article_page_path site.id, node, item }
  context "Check change log text for orphan/non-orphan  backup" do
    before { login_cms_user }

    it "show (case for non orphan backup)" do 
      backup = item.backups.limit(History.max_histories).to_a.first
      if backup.user_id
        group = backup.user ? Cms::Group.site(cms_site).in(id: backup.user.group_ids).first : nil
        if group
          text = "#{group.trailing_name} #{backup.user_name || backup.user.try(:name)}"
        else
          text = backup.user_name || backup.user.try(:name)
        end
      elsif backup.member_id
        text = "#{Cms::Member.model_name.human}: #{backup.member_name}"
      end
      visit show_path
      expect(find("tr[data-id='#{backup.id}']").text).to include("#{text}")
    end

    it ("show case for orphan backup") do
      orphan_backup = item.backups.limit(History.max_histories).to_a.first
      orphan_backup.update(user_id: nil, member_id: nil)
      item.reload
      visit show_path
      expect(find("tr[data-id='#{orphan_backup.id}']").text).to include("#{I18n.t("ss.system_operation", locale: I18n.default_locale)}")
    end

  end
end






