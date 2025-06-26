require 'spec_helper'

describe Gws::Tabular::Gws::ViewsController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user) { create :gws_user, group_ids: [ group.id ], gws_role_ids: admin.gws_role_ids }
  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: user }
  let!(:form) { create :gws_tabular_form, cur_site: site, cur_user: user, cur_space: space, state: 'publishing', revision: 1 }
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end
  let!(:column2) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 20,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end
  let!(:column3) do
    create(
      :gws_tabular_column_number_field, cur_site: site, cur_form: form, order: 30,
      field_type: "integer", min_value: 0, max_value: nil, default_value: 0)
  end

  context "liquid type view crud" do
    let(:name_translations) { i18n_translations(prefix: "name") }
    let(:name_ja) { name_translations[:ja] }
    let(:name_en) { name_translations[:en] }
    let(:authoring_permissions) { (Gws::Tabular::View::Base::AUTHORING_PERMISSIONS - %w(read)).sample(2) }
    let(:authoring_permission_labels) do
      authoring_permissions.map { I18n.t("gws/tabular.options.authoring_permission.#{_1}") }
    end
    let(:state) { %w(public closed).sample }
    let(:state_label) { I18n.t("ss.options.state.#{state}") }
    let(:order) { rand(1..10) }
    let(:default_state) { %w(enabled disabled).sample }
    let(:default_state_label) { I18n.t("ss.options.state.#{default_state}") }
    let(:memo) { Array.new(2) { "memo-#{unique_id}" } }

    let(:template_html) do
      <<~HTML.strip
        <p>hello #{unique_id}</p>
      HTML
    end
    let(:template_style) do
      <<~HTML.strip
        <style media="all">
          .foo-#{unique_id} { display: block; }
        </style>
      HTML
    end
    let(:limit_count) { rand(11..20) }

    let(:name2_translations) { i18n_translations(prefix: "name") }
    let(:name2_ja) { name2_translations[:ja] }
    let(:name2_en) { name2_translations[:en] }
    let(:authoring_permissions2) { (Gws::Tabular::View::Base::AUTHORING_PERMISSIONS - %w(read)).sample(2) }
    let(:authoring_permission2_labels) do
      authoring_permissions2.map { I18n.t("gws/tabular.options.authoring_permission.#{_1}") }
    end
    let(:state2) { %w(public closed).sample }
    let(:state2_label) { I18n.t("ss.options.state.#{state2}") }
    let(:order2) { rand(11..20) }
    let(:default_state2) { %w(enabled disabled).sample }
    let(:default_state2_label) { I18n.t("ss.options.state.#{default_state2}") }
    let(:memo2) { Array.new(2) { "memo-#{unique_id}" } }

    let(:template_html2) do
      <<~HTML.strip
        <p>hello #{unique_id}</p>
      HTML
    end
    let(:template_style2) do
      <<~HTML.strip
        <style media="all">
          .foo-#{unique_id} { display: block; }
        </style>
      HTML
    end
    let(:limit_count2) { rand(21..30) }

    it do
      #
      # New / Create
      #
      login_user user, to: gws_tabular_gws_spaces_path(site: site)
      click_on space.i18n_name
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/view/base")
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        choose I18n.t("mongoid.models.gws/tabular/view/liquid")
        select form.i18n_name, from: "item[form_id]"

        click_on I18n.t("ss.links.next")
      end
      within "form#item-form" do
        fill_in "item[i18n_name_translations][ja]", with: name_ja
        fill_in "item[i18n_name_translations][en]", with: name_en
        authoring_permission_labels.each do |permission_label|
          check permission_label
        end
        select state_label, from: "item[state]"
        fill_in "item[order]", with: order
        select default_state_label, from: "item[default_state]"
        fill_in "item[memo]", with: memo.join("\n")

        fill_in_code_mirror "item[template_html]", with: template_html
        fill_in_code_mirror "item[template_style]", with: template_style

        within "[data-field-name='orders']" do
          within "[data-column-id='#{column3.id}']" do
            check column3.name
            choose I18n.t("gws/tabular.options.order_direction.asc")
          end
          within "[data-column-id='updated']" do
            check I18n.t("mongoid.attributes.ss/document.updated")
            choose I18n.t("gws/tabular.options.order_direction.desc")
          end
        end
        within "[data-field-name='limit_count']" do
          fill_in "item[limit_count]", with: limit_count
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Tabular::View::Base.all.count).to eq 1
      Gws::Tabular::View::Base.all.first.tap do |view|
        expect(view.i18n_name_translations[:ja]).to eq name_ja
        expect(view.i18n_name_translations[:en]).to eq name_en
        expect(view.authoring_permissions).to eq (authoring_permissions + %w(read)).sort
        expect(view.state).to eq state
        expect(view.order).to eq order
        expect(view.default_state).to eq default_state
        expect(view.memo).to eq memo.join("\r\n")
        # Gws::Addon::Tabular::LiquidView
        expect(view.template_html).to eq template_html.gsub("\n", "\r\n")
        expect(view.template_style).to eq template_style.gsub("\n", "\r\n")
        expect(view.orders.count).to eq 2
        expect(view.orders).to include(
          { "column_id" => column3.id.to_s, "direction" => "asc" },
          { "column_id" => "updated", "direction" => "desc" })
        expect(view.limit_count).to eq limit_count
        # Gws::Addon::ReadableSetting
        expect(view.readable_setting_range).to eq "select"
        expect(view.readable_member_ids).to be_blank
        expect(view.readable_group_ids).to eq [ group.id ]
        expect(view.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(view.user_ids).to eq [ user.id ]
        expect(view.group_ids).to eq [ group.id ]
        expect(view.custom_group_ids).to be_blank
        #
        expect(view).to be_a(Gws::Tabular::View::Liquid)
        expect(view.site_id).to eq site.id
        expect(view.form_id).to eq form.id
        expect(view.deleted).to be_blank
      end

      #
      # Edit / Update
      #
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/view/base")
      end
      expect(page).to have_css(".list-item[data-id]", text: name_translations[I18n.locale])
      click_on name_translations[I18n.locale]
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[i18n_name_translations][ja]", with: name2_ja
        fill_in "item[i18n_name_translations][en]", with: name2_en
        authoring_permission_labels.each do |permission_label|
          uncheck permission_label
        end
        authoring_permission2_labels.each do |permission_label|
          check permission_label
        end
        select state2_label, from: "item[state]"
        fill_in "item[order]", with: order2
        select default_state2_label, from: "item[default_state]"
        fill_in "item[memo]", with: memo2.join("\n")

        fill_in_code_mirror "item[template_html]", with: template_html2
        fill_in_code_mirror "item[template_style]", with: template_style2
        fill_in "item[limit_count]", with: limit_count2

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Tabular::View::Base.all.count).to eq 1
      Gws::Tabular::View::Base.all.first.tap do |view|
        expect(view.i18n_name_translations[:ja]).to eq name2_ja
        expect(view.i18n_name_translations[:en]).to eq name2_en
        expect(view.authoring_permissions).to eq (authoring_permissions2 + %w(read)).sort
        expect(view.state).to eq state2
        expect(view.order).to eq order2
        expect(view.default_state).to eq default_state2
        expect(view.memo).to eq memo2.join("\r\n")
        # Gws::Addon::Tabular::LiquidView
        expect(view.template_html).to eq template_html2.gsub("\n", "\r\n")
        expect(view.template_style).to eq template_style2.gsub("\n", "\r\n")
        expect(view.orders.count).to eq 2
        expect(view.orders).to include(
          { "column_id" => column3.id.to_s, "direction" => "asc" },
          { "column_id" => "updated", "direction" => "desc" })
        expect(view.limit_count).to eq limit_count2
        # Gws::Addon::ReadableSetting
        expect(view.readable_setting_range).to eq "select"
        expect(view.readable_member_ids).to be_blank
        expect(view.readable_group_ids).to eq [ group.id ]
        expect(view.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(view.user_ids).to eq [ user.id ]
        expect(view.group_ids).to eq [ group.id ]
        expect(view.custom_group_ids).to be_blank
        #
        expect(view).to be_a(Gws::Tabular::View::Liquid)
        expect(view.site_id).to eq site.id
        expect(view.form_id).to eq form.id
        expect(view.deleted).to be_blank
      end

      #
      # Delete
      #
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/view/base")
      end
      expect(page).to have_css(".list-item[data-id]", text: name2_translations[I18n.locale])
      click_on name2_translations[I18n.locale]
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Tabular::View::Base.all.count).to eq 0
    end
  end
end
