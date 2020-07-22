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

  describe ".and_public" do
    context "when closed notice is given" do
      subject! { create(:sys_notice, state: "closed", release_date: nil, close_date: nil) }
      it { expect(Sys::Notice.and_public.count).to eq 0 }
    end

    context "when public notice without release plan is given" do
      subject! { create(:sys_notice, state: "public", release_date: nil, close_date: nil) }
      it { expect(Sys::Notice.and_public.first).to eq subject }
    end

    context "when public notice with release plan is given" do
      let(:current) { Time.zone.now.beginning_of_minute }
      let(:release_date) { current + 1.day }
      let(:close_date) { release_date + 1.day }
      subject! { create(:sys_notice, state: "public", release_date: release_date, close_date: close_date) }

      before do
        Sys::Notice.all.unset(:released)
        subject.reload
      end

      context "just before release date" do
        it do
          Timecop.freeze(release_date - 1.second) do
            expect(Sys::Notice.and_public.count).to eq 0
          end
        end
      end

      context "at release date" do
        it do
          Timecop.freeze(release_date) do
            expect(Sys::Notice.and_public.first).to eq subject
          end
        end
      end

      context "just before close date" do
        it do
          Timecop.freeze(close_date - 1.second) do
            expect(Sys::Notice.and_public.first).to eq subject
          end
        end
      end

      context "at close date" do
        it do
          Timecop.freeze(close_date) do
            expect(Sys::Notice.and_public.count).to eq 0
          end
        end
      end
    end
  end
end
