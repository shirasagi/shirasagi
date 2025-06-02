require 'spec_helper'

describe SS::File, dbscope: :example do
  before do
    sys_admin = SS::User.find(gws_user.id)
    expect(sys_admin.sys_roles.count).to eq 1
    sys_admin.sys_roles.each do |role|
      role.update(permissions: role.permissions + %w(edit_sys_users))
    end
    expect(sys_admin.sys_role_permissions["edit_sys_users"]).to be_present
  end

  describe ".resizing_options" do
    let!(:admin) { Gws::User.find(gws_user.id) }

    context "with admin" do
      context "without ss/image_resizing" do
        it do
          options = SS::File.resizing_options(user: admin)
          expect(options).to have(10).items

          max_width = max_height = 0
          options.each do |_label, size|
            w, h = size.split(",", 2)
            w = w.strip.to_i
            h = h.strip.to_i
            max_width = w if max_width < w
            max_height = h if max_height < h
          end
          expect(max_width).to eq 1_280
          expect(max_height).to eq 1_280
        end
      end

      context "with ss/image_resizing" do
        let!(:image_resize) { create :ss_image_resize, state: "enabled", max_width: 800, max_height: 800 }

        it do
          options = SS::File.resizing_options(user: admin)
          expect(options).to have(10).items

          max_width = max_height = 0
          options.each do |_label, size|
            w, h = size.split(",", 2)
            w = w.strip.to_i
            h = h.strip.to_i
            max_width = w if max_width < w
            max_height = h if max_height < h
          end
          expect(max_width).to eq 1_280
          expect(max_height).to eq 1_280
        end
      end
    end

    context "with user" do
      let!(:user) { create :gws_user, group_ids: gws_user.group_ids }

      context "without ss/image_resizing" do
        it do
          options = SS::File.resizing_options(user: user)
          expect(options).to have(10).items

          max_width = max_height = 0
          options.each do |_label, size|
            w, h = size.split(",", 2)
            w = w.strip.to_i
            h = h.strip.to_i
            max_width = w if max_width < w
            max_height = h if max_height < h
          end
          expect(max_width).to eq 1_280
          expect(max_height).to eq 1_280
        end
      end

      context "with ss/image_resizing" do
        let!(:image_resize) { create :ss_image_resize, state: "enabled", max_width: 800, max_height: 800 }

        it do
          options = SS::File.resizing_options(user: user)
          expect(options).to have(6).items

          max_width = max_height = 0
          options.each do |_label, size|
            w, h = size.split(",", 2)
            w = w.strip.to_i
            h = h.strip.to_i
            max_width = w if max_width < w
            max_height = h if max_height < h
          end
          expect(max_width).to be <= image_resize.max_width
          expect(max_height).to be <= image_resize.max_height
        end
      end
    end
  end
end
