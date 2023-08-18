require 'spec_helper'

describe "webmail_signatures", type: :feature, dbscope: :example do
  shared_examples "webmail signatures flow" do
    context "with auth" do
      before { login_webmail_user }

      it_behaves_like 'crud flow'
    end
  end

  describe "webmail_mode is account" do
    let(:imap_setting) { webmail_user.imap_settings.first || Webmail::ImapSetting.default }
    let(:imap) { Webmail::Imap::Base.new_by_user(webmail_user, imap_setting) }
    let(:account_scope) { imap.account_scope }
    let!(:item) { create :webmail_signature, account_scope.merge(cur_user: webmail_user) }
    let(:index_path) { webmail_signatures_path(account: 0) }

    it_behaves_like 'webmail signatures flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:imap_setting) { group.imap_setting || Webmail::ImapSetting.default }
    let(:imap) { Webmail::Imap::Base.new_by_group(group, imap_setting) }
    let(:account_scope) { imap.account_scope }
    let!(:item) { create :webmail_signature, account_scope.merge(cur_user: webmail_user) }
    let(:index_path) { webmail_signatures_path(account: group.id, webmail_mode: :group) }

    before { webmail_user.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail signatures flow'
  end
end
