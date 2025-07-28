require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:item) { create :gws_schedule_todo, cur_site: site, cur_user: user }

  before { login_gws_user }

  describe "#disable_all" do
    it do
      visit gws_schedule_todo_readables_path gws_site, "-"
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
      page.accept_confirm do
        find('.disable-all').click
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      item.reload
      expect(item.deleted).to be_present
    end
  end
end
