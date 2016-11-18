require 'spec_helper'

describe Sys::Notice, dbscope: :example do
  context "with defaults" do
    subject { described_class.create!(name: unique_id) }
    its(:name) { is_expected.not_to be_nil }
    its(:notice_severity) { is_expected.to eq described_class::NOTICE_SEVERITY_NORMAL }
    its(:notice_target) { is_expected.to eq [] }
  end

  context "target_to" do
    let(:notice) { create( :sys_notice ) }

    it ".sys_admin_notice" do
      notice.notice_target << Sys::Notice::NOTICE_TARGET_SYS_ADMIN
      notice.save!

      expect(Sys::Notice.sys_admin_notice.first).not_to eq nil
      expect(Sys::Notice.cms_admin_notice.first).to eq nil
      expect(Sys::Notice.gw_admin_notice.first).to eq nil
      expect(Sys::Notice.and_show_login.first).to eq nil
    end

    it ".cms_admin_notice" do
      notice.notice_target << Sys::Notice::NOTICE_TARGET_CMS_ADMIN
      notice.save!

      expect(Sys::Notice.sys_admin_notice.first).to eq nil
      expect(Sys::Notice.cms_admin_notice.first).not_to eq nil
      expect(Sys::Notice.gw_admin_notice.first).to eq nil
      expect(Sys::Notice.and_show_login.first).to eq nil
    end

    it ".cms_admin_notice" do
      notice.notice_target << Sys::Notice::NOTICE_TARGET_GROUP_WEAR
      notice.save!

      expect(Sys::Notice.sys_admin_notice.first).to eq nil
      expect(Sys::Notice.cms_admin_notice.first).to eq nil
      expect(Sys::Notice.gw_admin_notice.first).not_to eq nil
      expect(Sys::Notice.and_show_login.first).to eq nil
    end

    it ".cms_admin_notice" do
      notice.notice_target << Sys::Notice::NOTICE_TARGET_LOGIN_VIEW
      notice.save!

      expect(Sys::Notice.sys_admin_notice.first).to eq nil
      expect(Sys::Notice.cms_admin_notice.first).to eq nil
      expect(Sys::Notice.gw_admin_notice.first).to eq nil
      expect(Sys::Notice.and_show_login.first).not_to eq nil
    end

    it ".cms_admin_notice and .sys_admin_notice" do
      notice.notice_target << Sys::Notice::NOTICE_TARGET_CMS_ADMIN
      notice.notice_target << Sys::Notice::NOTICE_TARGET_SYS_ADMIN
      notice.save!

      expect(Sys::Notice.sys_admin_notice.first).not_to eq nil
      expect(Sys::Notice.cms_admin_notice.first).not_to eq nil
      expect(Sys::Notice.gw_admin_notice.first).to eq nil
      expect(Sys::Notice.and_show_login.first).to eq nil
    end

    it "notice count" do
      notice.notice_target << Sys::Notice::NOTICE_TARGET_SYS_ADMIN
      notice.save!

      notice2 = create(:sys_notice)
      notice2.notice_target << Sys::Notice::NOTICE_TARGET_SYS_ADMIN
      notice2.notice_target << Sys::Notice::NOTICE_TARGET_LOGIN_VIEW
      notice2.save!

      expect(Sys::Notice.and_show_login.count).to eq 1
      expect(Sys::Notice.sys_admin_notice.count).to eq 2
      expect(Sys::Notice.cms_admin_notice.count).to eq 0
      expect(Sys::Notice.gw_admin_notice.count).to eq 0
    end

  end
end
