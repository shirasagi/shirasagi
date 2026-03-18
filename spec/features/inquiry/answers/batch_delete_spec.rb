require 'spec_helper'

describe "inquiry_answers", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: user.group_ids }
  let!(:answer1) do
    Inquiry::Answer.new(
      cur_site: site, cur_node: node, remote_addr: "X.X.X.X", user_agent: unique_id, group_ids: user.group_ids)
  end

  before do
    name_column = attributes_for(:inquiry_column_name)
      .then { _1.reverse_merge(cur_site: site) }
      .then { _1.merge(question: 'enabled') }
      .then { node.columns.create! _1 }

    data = {}
    data[name_column.id] = [unique_id]

    answer1.set_data(data)
    answer1.save!
  end

  context "batch delete" do
    it do
      login_user user, to: inquiry_forms_path(site: site, cid: node)
      within first(".mod-navi") do
        click_on I18n.t("inquiry.answer")
      end
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
      page.accept_confirm(I18n.t("ss.confirm.delete")) do
        within ".list-head-action" do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { answer1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
