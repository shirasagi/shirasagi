require 'spec_helper'

describe SS::File, dbscope: :example do
  let(:file_path) do
    case rand(0..3)
    when 0
      "#{Rails.root}/spec/fixtures/ss/logo.png"
    when 1
      "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
    when 2
      "#{Rails.root}/spec/fixtures/sys/postal_code.zip"
    when 3
      "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
    end
  end

  describe "previewable?" do
    context "cms" do
      context "with Cms::File" do
        let!(:group0) { cms_group }
        let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:site1) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site2) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site1_role1) { create :cms_role, cur_site: site1, permissions: %w(read_private_cms_files) }
        let!(:site2_role1) { create :cms_role, cur_site: site2, permissions: %w(read_private_cms_files) }
        let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ site1_role1.id ] }
        let!(:user2) { create :cms_test_user, group_ids: [ group2.id ], cms_role_ids: [ site2_role1.id ] }
        let!(:user3) { create :cms_test_user, group_ids: [ group1.id, group2.id ], cms_role_ids: [] }
        let!(:file) do
          tmp_ss_file(
            Cms::File, site: site1, user: user1, model: "cms/file", contents: file_path, group_ids: [ group1.id, group2.id ]
          )
        end

        it do
          # no arguments
          expect(file.previewable?).to be_falsey

          # only site
          expect(file.previewable?(site: site1)).to be_falsey
          expect(file.previewable?(site: site2)).to be_falsey

          # user1 has permissions to preview cms/file on site1
          expect(file.previewable?(user: user1)).to be_falsey
          expect(file.previewable?(user: user1, site: site1)).to be_truthy
          expect(file.previewable?(user: user1, site: site2)).to be_falsey

          # user2 has permissions to preview cms/file on site2
          expect(file.previewable?(user: user2)).to be_falsey
          expect(file.previewable?(user: user2, site: site1)).to be_falsey
          expect(file.previewable?(user: user2, site: site2)).to be_falsey

          # user3 has no permissions to preview cms/file
          expect(file.previewable?(user: user3)).to be_falsey
          expect(file.previewable?(user: user3, site: site1)).to be_falsey
          expect(file.previewable?(user: user3, site: site2)).to be_falsey
        end
      end

      context "with Cms::HistoryArchiveFile" do
        let!(:group0) { cms_group }
        let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:site1) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site2) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site1_role1) { create :cms_role, cur_site: site1, permissions: %w(use_cms_tools) }
        let!(:site2_role1) { create :cms_role, cur_site: site2, permissions: %w(use_cms_tools) }
        let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ site1_role1.id ] }
        let!(:user2) { create :cms_test_user, group_ids: [ group2.id ], cms_role_ids: [ site2_role1.id ] }
        let!(:user3) { create :cms_test_user, group_ids: [ group1.id, group2.id ], cms_role_ids: [] }
        let!(:file) do
          tmp_ss_file(
            Cms::HistoryArchiveFile, site: site1, user: user1, model: "sys/history_archive_file", contents: file_path
          )
        end

        it do
          # no arguments
          expect(file.previewable?).to be_falsey

          # only site
          expect(file.previewable?(site: site1)).to be_falsey
          expect(file.previewable?(site: site2)).to be_falsey

          # user1 has permissions to preview cms/history_archive_file on site1
          expect(file.previewable?(user: user1)).to be_falsey
          expect(file.previewable?(user: user1, site: site1)).to be_truthy
          expect(file.previewable?(user: user1, site: site2)).to be_falsey

          # user2 has permissions to preview cms/history_archive_file on site2
          expect(file.previewable?(user: user2)).to be_falsey
          expect(file.previewable?(user: user2, site: site1)).to be_falsey
          expect(file.previewable?(user: user2, site: site2)).to be_falsey

          # user3 has no permissions to preview cms/history_archive_file
          expect(file.previewable?(user: user3)).to be_falsey
          expect(file.previewable?(user: user3, site: site1)).to be_falsey
          expect(file.previewable?(user: user3, site: site2)).to be_falsey
        end
      end

      context "with Opendata::ResourceDownloadHistory::ArchiveFile" do
        let!(:group0) { cms_group }
        let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:site1) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site2) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site1_role1) { create :cms_role, cur_site: site1, permissions: %w(read_opendata_histories) }
        let!(:site2_role1) { create :cms_role, cur_site: site2, permissions: %w(read_opendata_histories) }
        let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ site1_role1.id ] }
        let!(:user2) { create :cms_test_user, group_ids: [ group2.id ], cms_role_ids: [ site2_role1.id ] }
        let!(:user3) { create :cms_test_user, group_ids: [ group1.id, group2.id ], cms_role_ids: [] }
        let!(:file) do
          model = [ Opendata::ResourceDownloadHistory::ArchiveFile, Opendata::ResourcePreviewHistory::ArchiveFile ].sample
          tmp_ss_file(
            model, site: site1, user: user1, model: model.model_name.i18n_key.to_s, contents: file_path
          )
        end

        it do
          # no arguments
          expect(file.previewable?).to be_falsey

          # only site
          expect(file.previewable?(site: site1)).to be_falsey
          expect(file.previewable?(site: site2)).to be_falsey

          # user1 has permissions to preview cms/resource_download_history/archive_file on site1
          expect(file.previewable?(user: user1)).to be_falsey
          expect(file.previewable?(user: user1, site: site1)).to be_truthy
          expect(file.previewable?(user: user1, site: site2)).to be_falsey

          # user2 has permissions to preview cms/resource_download_history/archive_file on site2
          expect(file.previewable?(user: user2)).to be_falsey
          expect(file.previewable?(user: user2, site: site1)).to be_falsey
          expect(file.previewable?(user: user2, site: site2)).to be_falsey

          # user3 has no permissions to preview cms/resource_download_history/archive_file
          expect(file.previewable?(user: user3)).to be_falsey
          expect(file.previewable?(user: user3, site: site1)).to be_falsey
          expect(file.previewable?(user: user3, site: site2)).to be_falsey
        end
      end

      context "with Cms::Page" do
        let!(:group0) { cms_group }
        let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:site1) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site2) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site1_role1) { create :cms_role, cur_site: site1, permissions: %w(read_private_cms_pages) }
        let!(:site2_role1) { create :cms_role, cur_site: site2, permissions: %w(read_private_cms_pages) }
        let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ site1_role1.id ] }
        let!(:user2) { create :cms_test_user, group_ids: [ group2.id ], cms_role_ids: [ site2_role1.id ] }
        let!(:user3) { create :cms_test_user, group_ids: [ group1.id, group2.id ], cms_role_ids: [] }
        let!(:file) do
          tmp_ss_file(site: site1, user: user1, contents: file_path)
        end
        let!(:item) do
          html = <<~HTML
            <p><img alt="#{file.name}" src="#{file.url}" /></p>
          HTML
          item = create(
            :cms_page, cur_site: site1, cur_user: user1, html: html, file_ids: [ file.id ], state: state,
            group_ids: [ group1.id, group2.id ]
          )
          file.reload
          item
        end

        context "with state 'public'" do
          let(:state) { "public" }

          it do
            # no arguments
            expect(file.previewable?).to be_falsey

            # only site
            expect(file.previewable?(site: site1)).to be_truthy
            expect(file.previewable?(site: site2)).to be_falsey

            # user1 is a owner of file and has permissions to read cms/page on site1
            expect(file.previewable?(user: user1)).to be_truthy
            expect(file.previewable?(user: user1, site: site1)).to be_truthy
            expect(file.previewable?(user: user1, site: site2)).to be_falsey

            # user2 has permissions to read cms/page on site2
            expect(file.previewable?(user: user2)).to be_falsey
            expect(file.previewable?(user: user2, site: site1)).to be_truthy
            expect(file.previewable?(user: user2, site: site2)).to be_falsey

            # user3 has no permissions to read cms/page
            expect(file.previewable?(user: user3)).to be_falsey
            expect(file.previewable?(user: user3, site: site1)).to be_truthy
            expect(file.previewable?(user: user3, site: site2)).to be_falsey
          end
        end

        context "with state 'closed'" do
          let(:state) { "closed" }

          it do
            # no arguments
            expect(file.previewable?).to be_falsey

            # only site
            expect(file.previewable?(site: site1)).to be_falsey
            expect(file.previewable?(site: site2)).to be_falsey

            # user1 is a owner of file and has permissions to read cms/page on site1
            expect(file.previewable?(user: user1)).to be_truthy
            expect(file.previewable?(user: user1, site: site1)).to be_truthy
            expect(file.previewable?(user: user1, site: site2)).to be_falsey

            # user2 has permissions to read cms/page on site2
            expect(file.previewable?(user: user2)).to be_falsey
            expect(file.previewable?(user: user2, site: site1)).to be_falsey
            expect(file.previewable?(user: user2, site: site2)).to be_falsey

            # user3 has no permissions to read cms/page
            expect(file.previewable?(user: user3)).to be_falsey
            expect(file.previewable?(user: user3, site: site1)).to be_falsey
            expect(file.previewable?(user: user3, site: site2)).to be_falsey
          end
        end
      end

      context "with Member::BlogPage" do
        let!(:group0) { cms_group }
        let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
        let!(:site1) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site2) { create :cms_site_unique, group_ids: [ group0.id, group1.id, group2.id ] }
        let!(:site1_role1) { create :cms_role, cur_site: site1, permissions: %w(read_private_member_blogs) }
        let!(:site2_role1) { create :cms_role, cur_site: site2, permissions: %w(read_private_member_blogs) }
        let!(:user1) { create :cms_test_user, group_ids: [ group1.id ], cms_role_ids: [ site1_role1.id ] }
        let!(:user2) { create :cms_test_user, group_ids: [ group2.id ], cms_role_ids: [ site2_role1.id ] }
        let!(:user3) { create :cms_test_user, group_ids: [ group1.id, group2.id ], cms_role_ids: [] }
        let!(:site1_member1) { create :cms_member, cur_site: site1 }
        let!(:site2_member1) { create :cms_member, cur_site: site2 }
        let!(:file) do
          tmp_ss_file(
            Member::File, site: site1, model: "member/temp_file", contents: file_path, cur_member: site1_member1
          )
        end
        let(:layout) { create :member_blog_layout }
        let!(:site1_node1) do
          create(
            :member_node_blog_page, cur_site: site1, cur_member: site1_member1, layout: layout, page_layout: layout,
            group_ids: [ group1.id, group2.id ])
        end
        let!(:item) do
          html = <<~HTML
            <p><img alt="#{file.name}" src="#{file.url}" /></p>
          HTML
          item = create(
            :member_blog_page, cur_user: nil, cur_site: site1, cur_node: site1_node1, cur_member: site1_member1, layout: layout,
            html: html, file_ids: [ file.id ], state: state, group_ids: [ group1.id, group2.id ]
          )
          file.reload
          item
        end

        context "with state 'public'" do
          let(:state) { "public" }

          it do
            # no arguments
            expect(file.previewable?).to be_falsey

            # only site
            expect(file.previewable?(site: site1)).to be_truthy
            expect(file.previewable?(site: site2)).to be_falsey

            # user1 has permissions to read member/blog_page on site1
            expect(file.previewable?(user: user1)).to be_truthy
            expect(file.previewable?(user: user1, site: site1)).to be_truthy
            expect(file.previewable?(user: user1, site: site2)).to be_falsey

            # user2 has permissions to read member/blog_page on site2
            expect(file.previewable?(user: user2)).to be_falsey
            expect(file.previewable?(user: user2, site: site1)).to be_truthy
            expect(file.previewable?(user: user2, site: site2)).to be_falsey

            # user3 has no permissions to read member/blog_page
            expect(file.previewable?(user: user3)).to be_falsey
            expect(file.previewable?(user: user3, site: site1)).to be_truthy
            expect(file.previewable?(user: user3, site: site2)).to be_falsey

            # site1_member1 owns file on site1
            expect(file.previewable?(member: site1_member1)).to be_falsey
            expect(file.previewable?(member: site1_member1, site: site1)).to be_truthy
            expect(file.previewable?(member: site1_member1, site: site2)).to be_falsey

            # site2_member1 owns no files on any sites
            expect(file.previewable?(member: site2_member1)).to be_falsey
            expect(file.previewable?(member: site2_member1, site: site1)).to be_truthy
            expect(file.previewable?(member: site2_member1, site: site2)).to be_falsey
          end
        end

        context "with state 'closed'" do
          let(:state) { "closed" }

          it do
            # no arguments
            expect(file.previewable?).to be_falsey

            # only site
            expect(file.previewable?(site: site1)).to be_falsey
            expect(file.previewable?(site: site2)).to be_falsey

            # user1 has permissions to read member/blog_page on site1
            expect(file.previewable?(user: user1)).to be_truthy
            expect(file.previewable?(user: user1, site: site1)).to be_truthy
            expect(file.previewable?(user: user1, site: site2)).to be_falsey

            # user2 has permissions to read member/blog_page on site2
            expect(file.previewable?(user: user2)).to be_falsey
            expect(file.previewable?(user: user2, site: site1)).to be_falsey
            expect(file.previewable?(user: user2, site: site2)).to be_falsey

            # user3 has no permissions to read member/blog_page
            expect(file.previewable?(user: user3)).to be_falsey
            expect(file.previewable?(user: user3, site: site1)).to be_falsey
            expect(file.previewable?(user: user3, site: site2)).to be_falsey

            # site1_member1 owns file on site1
            expect(file.previewable?(member: site1_member1)).to be_falsey
            expect(file.previewable?(member: site1_member1, site: site1)).to be_truthy
            expect(file.previewable?(member: site1_member1, site: site2)).to be_falsey

            # site2_member1 owns no files on any sites
            expect(file.previewable?(member: site2_member1)).to be_falsey
            expect(file.previewable?(member: site2_member1, site: site1)).to be_falsey
            expect(file.previewable?(member: site2_member1, site: site2)).to be_falsey
          end
        end
      end
    end

    context "sns/sys/ss" do
      context "with Sys::HistoryArchiveFile" do
        let!(:group0) { create :sys_group, name: unique_id }
        let!(:group1) { create :sys_group, name: "#{group0.name}/#{unique_id}" }
        let!(:group2) { create :sys_group, name: "#{group0.name}/#{unique_id}" }
        let!(:role1) { create :sys_role, permissions: %w(edit_sys_users) }
        let!(:user1) { create :sys_user_sample, group_ids: [ group1.id ], sys_role_ids: [ role1.id ] }
        let!(:user2) { create :sys_user_sample, group_ids: [ group2.id ], sys_role_ids: [ role1.id ] }
        let!(:user3) { create :sys_user_sample, group_ids: [ group1.id, group2.id ], sys_role_ids: [] }
        let!(:file) do
          tmp_ss_file(
            Sys::HistoryArchiveFile, user: user1, model: "sys/history_archive_file", contents: file_path
          )
        end

        it do
          # no arguments
          expect(file.previewable?).to be_falsey

          # user1 is owner of sys/history_archive_file and has permissions to preview sys/history_archive_file
          expect(file.previewable?(user: user1)).to be_truthy

          # user2 has permissions to preview sys/history_archive_file
          expect(file.previewable?(user: user2)).to be_truthy

          # user3 has no permissions to preview sys/history_archive_file
          expect(file.previewable?(user: user3)).to be_falsey
        end
      end

      context "with SS::UserFile" do
        let!(:group0) { create :sys_group, name: unique_id }
        let!(:user1) { create :sys_user_sample, group_ids: [ group0.id ], sys_role_ids: [] }
        let!(:user2) { create :sys_user_sample, group_ids: [ group0.id ], sys_role_ids: [] }
        let!(:file) do
          tmp_ss_file(
            SS::UserFile, user: user1, model: "ss/user_file", contents: file_path
          )
        end

        it do
          # no arguments
          expect(file.previewable?).to be_falsey

          # user1 is owner of ss/user_file
          expect(file.previewable?(user: user1)).to be_truthy

          # user2 isn't owner of ss/user_file
          expect(file.previewable?(user: user2)).to be_falsey
        end
      end

      context "with SS::TempFile" do
        let!(:group0) { create :sys_group, name: unique_id }
        let!(:user1) { create :sys_user_sample, group_ids: [ group0.id ], sys_role_ids: [] }
        let!(:user2) { create :sys_user_sample, group_ids: [ group0.id ], sys_role_ids: [] }
        let!(:file) do
          tmp_ss_file(
            SS::TempFile, user: user1, model: "ss/temp_file", contents: file_path
          )
        end

        it do
          # no arguments
          expect(file.previewable?).to be_falsey

          # user1 is owner of ss/user_file
          expect(file.previewable?(user: user1)).to be_truthy

          # user2 isn't owner of ss/user_file
          expect(file.previewable?(user: user2)).to be_falsey
        end
      end

      context "with SS::LinkFile" do
        let!(:group0) { create :sys_group, name: unique_id }
        let!(:group1) { create :sys_group, name: "#{group0.name}/#{unique_id}" }
        let!(:group2) { create :sys_group, name: "#{group0.name}/#{unique_id}" }
        let!(:role1) { create :sys_role, permissions: %w(edit_sys_users) }
        let!(:user1) { create :sys_user_sample, group_ids: [ group1.id ], sys_role_ids: [ role1.id ] }
        let!(:user2) { create :sys_user_sample, group_ids: [ group2.id ], sys_role_ids: [ role1.id ] }
        let!(:user3) { create :sys_user_sample, group_ids: [ group1.id, group2.id ], sys_role_ids: [] }
        let!(:file) do
          tmp_ss_file(
            SS::LinkFile, user: user1, model: "ss/link_file", contents: file_path, link_url: unique_url
          )
        end
        let!(:setting) do
          setting = Sys::Setting.create(time: 15, width: 480, file_ids: [ file.id ])
          file.reload
          setting
        end

        it do
          # no arguments
          expect(file.previewable?).to be_truthy

          # user1
          expect(file.previewable?(user: user1)).to be_truthy

          # user2
          expect(file.previewable?(user: user2)).to be_truthy

          # user3
          expect(file.previewable?(user: user3)).to be_truthy
        end
      end

      context "with SS::LogoFile" do
        let(:file_path) do
          # ロゴは画像のみ可
          case rand(0..1)
          when 0
            "#{Rails.root}/spec/fixtures/ss/logo.png"
          else
            "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          end
        end
        let!(:file) do
          tmp_ss_file(
            SS::LogoFile, user: user1, model: "ss/logo_file", contents: file_path
          )
        end

        context "on cms" do
          let!(:group0) { cms_group }
          let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
          let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
          let!(:site1) { create :cms_site_unique, group_ids: [ group1.id ] }
          let!(:site2) { create :cms_site_unique, group_ids: [ group2.id ] }
          let!(:user1) { create :cms_test_user, group_ids: [ group1.id ] }
          let!(:user2) { create :cms_test_user, group_ids: [ group2.id ] }
          let!(:user3) { create :cms_test_user, group_ids: [ group1.id, group2.id ] }

          before do
            site1.logo_application_image = file
            site1.save!

            file.reload
          end

          it do
            # no arguments
            expect(file.previewable?).to be_falsey

            # only site
            expect(file.previewable?(site: site1)).to be_falsey
            expect(file.previewable?(site: site2)).to be_falsey

            # user1 is only on site1
            expect(file.previewable?(user: user1)).to be_truthy

            # user2 is only on site2
            expect(file.previewable?(user: user2)).to be_falsey

            # user3 is on both site1 and site2
            expect(file.previewable?(user: user3)).to be_truthy
          end
        end

        context "on gws" do
          let!(:site1) { create :gws_group, name: unique_id }
          let!(:site2) { create :gws_group, name: unique_id }
          let!(:site1_group1) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
          let!(:site2_group1) { create :gws_group, name: "#{site2.name}/#{unique_id}" }
          let!(:user1) { create :gws_user, group_ids: [ site1_group1.id ] }
          let!(:user2) { create :gws_user, group_ids: [ site2_group1.id ] }
          let!(:user3) { create :gws_user, group_ids: [ site1_group1.id, site2_group1.id ] }

          before do
            site1.logo_application_image = file
            site1.save!

            file.reload
          end

          it do
            # no arguments
            expect(file.previewable?).to be_falsey

            # user1 is only on site1
            expect(file.previewable?(user: user1)).to be_truthy

            # user2 is only on site2
            expect(file.previewable?(user: user2)).to be_falsey

            # user3 is on both site1 and site2
            expect(file.previewable?(user: user3)).to be_truthy
          end
        end
      end
    end

    context "gws" do
      context "with Gws::Schedule::Plan" do
        let!(:site1) { create :gws_group, name: unique_id }
        let!(:site1_group1) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
        let!(:site1_group2) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
        let!(:site1_role_admin) { create :gws_role_admin, cur_site: site1 }
        let!(:site1_role_read) { create :gws_role, cur_site: site1, permissions: %w(read_private_gws_schedule_plans) }
        let!(:user_admin) { create :gws_user, group_ids: [ site1.id ], gws_role_ids: [ site1_role_admin.id ] }
        let!(:user1) { create :gws_user, group_ids: [ site1_group1.id ], gws_role_ids: [ site1_role_read.id ] }
        let!(:user2) { create :gws_user, group_ids: [ site1_group2.id ], gws_role_ids: [ site1_role_read.id ] }
        let!(:file) { tmp_ss_file(contents: file_path, user: user_admin) }
        let!(:item) do
          item = create(
            :gws_schedule_plan, cur_site: site1, cur_user: user_admin, file_ids: [ file.id ],
            member_ids: member_ids, member_group_ids: nil, member_custom_group_ids: nil,
            readable_group_ids: nil, readable_member_ids: readable_member_ids, readable_custom_group_ids: nil,
            group_ids: nil, user_ids: user_ids, custom_group_ids: nil
          )
          file.reload
          item
        end
        let!(:cms_site) { create :cms_site_unique, group_ids: [ site1.id ] }

        context "with member_ids" do
          let(:member_ids) { [ user1.id ] }
          let(:readable_member_ids) { [ user_admin.id ] }
          let(:user_ids) { [ user_admin.id ] }

          it do
            expect(file.owner_item_type).to eq item.class.name
            expect(file.owner_item_id).to eq item.id

            # no arguments
            expect(file.previewable?).to be_falsey

            # only user
            expect(file.previewable?(user: user1)).to be_truthy
            expect(file.previewable?(user: user2)).to be_falsey

            # with cms site: CMS サイトとグループウェアのドメインを同じ設定で運用している場合
            expect(file.previewable?(user: user1, site: cms_site)).to be_truthy
            expect(file.previewable?(user: user2, site: cms_site)).to be_falsey
          end
        end

        context "with readable_member_ids" do
          let(:member_ids) { [ user_admin.id ] }
          let(:readable_member_ids) { [ user1.id ] }
          let(:user_ids) { [ user_admin.id ] }

          it do
            expect(file.owner_item_type).to eq item.class.name
            expect(file.owner_item_id).to eq item.id

            # no arguments
            expect(file.previewable?).to be_falsey

            # only user
            expect(file.previewable?(user: user1)).to be_truthy
            expect(file.previewable?(user: user2)).to be_falsey

            # with cms site: CMS サイトとグループウェアのドメインを同じ設定で運用している場合
            expect(file.previewable?(user: user1, site: cms_site)).to be_truthy
            expect(file.previewable?(user: user2, site: cms_site)).to be_falsey
          end
        end

        context "with user_ids" do
          let(:member_ids) { [ user_admin.id ] }
          let(:readable_member_ids) { [ user_admin.id ] }
          let(:user_ids) { [ user1.id ] }

          it do
            expect(file.owner_item_type).to eq item.class.name
            expect(file.owner_item_id).to eq item.id

            # no arguments
            expect(file.previewable?).to be_falsey

            # only user
            expect(file.previewable?(user: user1)).to be_truthy
            expect(file.previewable?(user: user2)).to be_falsey

            # with cms site: CMS サイトとグループウェアのドメインを同じ設定で運用している場合
            expect(file.previewable?(user: user1, site: cms_site)).to be_truthy
            expect(file.previewable?(user: user2, site: cms_site)).to be_falsey
          end
        end
      end
    end
  end
end
