require 'spec_helper'

describe Webmail, type: :model, dbscope: :example do
  context "when webmail/address is created" do
    it do
      expect { create(:webmail_address) }.to \
        change { Webmail.find_webmail_quota_used }.by_at_least(50)
    end
  end

  context "when webmail/address_group is created" do
    it do
      expect { create(:webmail_address_group) }.to \
        change { Webmail.find_webmail_quota_used }.by_at_least(50)
    end
  end

  context "when webmail/group is created" do
    context "when child group is created" do
      it do
        expect { create(:webmail_group, name: unique_id) }.to \
          change { Webmail.find_webmail_quota_used }.by_at_least(50)
      end
    end

    context "when none-active group is created" do
      it do
        expect { create(:webmail_group, name: unique_id, expiration_date: Time.zone.now - 1.minute) }.to \
          change { Webmail.find_webmail_quota_used }.by_at_least(50)
      end
    end
  end

  context "when webmail/filter is created" do
    it do
      expect { create(:webmail_filter) }.to \
        change { Webmail.find_webmail_quota_used }.by_at_least(50)
    end
  end

  context "when webmail/role is created" do
    it do
      expect { create(:webmail_role_admin) }.to \
        change { Webmail.find_webmail_quota_used }.by_at_least(500)
    end
  end

  context "when webmail/user is created" do
    context "with usual case" do
      it do
        expect { create(:webmail_user, uid: unique_id, email: "#{unique_id}@example.jp") }.to \
          change { Webmail.find_webmail_quota_used }.by_at_least(400)
      end
    end

    context "when none-active user is created" do
      it do
        expectation = expect do
          time = Time.zone.now - 1.minute
          create(:webmail_user, uid: unique_id, email: "#{unique_id}@example.jp", account_expiration_date: time)
        end
        expectation.to change { Webmail.find_webmail_quota_used }.by_at_least(400)
      end
    end
  end
end
