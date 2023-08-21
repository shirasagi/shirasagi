require 'spec_helper'

describe Cms::NodeHelper, type: :helper, dbscope: :example do
  let(:site) { cms_site }
  let!(:node) do
    create(:article_node_page, cur_site: site)
  end

  describe "#cms_syntax_check_enabled?" do
    let(:default_check_logic) do
      proc do |site, node|
        syntax_check = true
        syntax_check = site.syntax_check_enabled? if syntax_check
        if node && node.respond_to?(:syntax_check_enabled?) && syntax_check
          syntax_check = node.syntax_check_enabled?
        end
        syntax_check
      end
    end

    context "both on site and node is enabled" do
      before do
        site.syntax_check = "enabled"
        site.save!

        node.syntax_check = "enabled"
        node.save!
      end

      it do
        @cur_site = site
        @cur_node = node

        expect(default_check_logic.call(site, node)).to be_truthy
        expect(helper.cms_syntax_check_enabled?).to be_truthy
      end
    end

    context "syntax check is enabled on site, but is disabled on node" do
      before do
        site.syntax_check = "enabled"
        site.save!

        node.syntax_check = "disabled"
        node.save!
      end

      it do
        @cur_site = site
        @cur_node = node

        expect(default_check_logic.call(site, node)).to be_falsey
        expect(helper.cms_syntax_check_enabled?).to be_falsey
      end
    end

    context "syntax check is disabled on site, but is enabled on node" do
      before do
        site.syntax_check = "disabled"
        site.save!

        node.syntax_check = "enabled"
        node.save!
      end

      it do
        @cur_site = site
        @cur_node = node

        expect(default_check_logic.call(site, node)).to be_falsey
        expect(helper.cms_syntax_check_enabled?).to be_falsey
      end
    end

    context "both on site and node is disabled" do
      before do
        site.syntax_check = "disabled"
        site.save!

        node.syntax_check = "disabled"
        node.save!
      end

      it do
        @cur_site = site
        @cur_node = node

        expect(default_check_logic.call(site, node)).to be_falsey
        expect(helper.cms_syntax_check_enabled?).to be_falsey
      end
    end

    context "with column" do
      let!(:item) { create :article_page, cur_site: site, cur_node: node }
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
      let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form, order: 1) }
      let(:default_check_logic) do
        proc do |site, node, column, item|
          inplace_syntax_check = column.syntax_check_enabled?
          inplace_syntax_check = site.syntax_check_enabled? if inplace_syntax_check
          inplace_syntax_check = node.syntax_check_enabled? if inplace_syntax_check && node
          if node && node.respond_to?(:syntax_check_enabled?) && inplace_syntax_check
            inplace_syntax_check = node.syntax_check_enabled?
          end
          if item.parent && item.parent.respond_to?(:syntax_check_enabled?) && inplace_syntax_check
            inplace_syntax_check = item.parent.syntax_check_enabled?
          end
          inplace_syntax_check
        end
      end

      context "both on site and node is enabled" do
        before do
          site.syntax_check = "enabled"
          site.save!

          node.syntax_check = "enabled"
          node.save!
        end

        it do
          @cur_site = site
          @cur_node = node
          @cur_column = column
          @item = item

          expect(default_check_logic.call(site, node, column, item)).to be_truthy
          expect(helper.cms_syntax_check_enabled?(column: true, parent: true)).to be_truthy
        end
      end

      context "syntax check is enabled on site, but is disabled on node" do
        before do
          site.syntax_check = "enabled"
          site.save!

          node.syntax_check = "disabled"
          node.save!
        end

        it do
          @cur_site = site
          @cur_node = node
          @cur_column = column
          @item = item

          expect(default_check_logic.call(site, node, column, item)).to be_falsey
          expect(helper.cms_syntax_check_enabled?(column: true, parent: true)).to be_falsey
        end
      end

      context "syntax check is disabled on site, but is enabled on node" do
        before do
          site.syntax_check = "disabled"
          site.save!

          node.syntax_check = "enabled"
          node.save!
        end

        it do
          @cur_site = site
          @cur_node = node

          expect(default_check_logic.call(site, node, column, item)).to be_falsey
          expect(helper.cms_syntax_check_enabled?(column: true, parent: true)).to be_falsey
        end
      end

      context "both on site and node is disabled" do
        before do
          site.syntax_check = "disabled"
          site.save!

          node.syntax_check = "disabled"
          node.save!
        end

        it do
          @cur_site = site
          @cur_node = node

          expect(default_check_logic.call(site, node, column, item)).to be_falsey
          expect(helper.cms_syntax_check_enabled?(column: true, parent: true)).to be_falsey
        end
      end
    end
  end

  describe "#colored_state_label" do
    let(:now) { Time.zone.now.change(usec: 0) }

    before do
      site.page_expiration_state = "enabled"
      site.page_expiration_before = "90.days"
      site.approve_remind_state = "enabled"
      site.approve_remind_later = "1.day"
      site.save!
    end

    context "with public page" do
      let(:item) do
        Timecop.freeze(now) { create(:article_page, cur_site: site, cur_node: node, state: "public") }
      end

      it do
        @cur_site = site

        (now + SS::Duration.parse(site.approve_remind_later)).tap do |approval_limit|
          Timecop.freeze(approval_limit) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(approval_limit + 1.second) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
        (now + SS::Duration.parse(site.page_expiration_before)).tap do |publication_limit|
          Timecop.freeze(publication_limit) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.end_of_day) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.tomorrow.beginning_of_day) do
            css_class = %w(state state-public-expired).join(" ")
            label = "#{I18n.t("ss.state.public")}#{I18n.t("cms.state_expired_suffix")}"
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
      end
    end

    context "with non-released page" do
      let(:item) do
        Timecop.freeze(now) { create(:article_page, cur_site: site, cur_node: node, state: "closed") }
      end

      it do
        @cur_site = site

        (now + SS::Duration.parse(site.approve_remind_later)).tap do |approval_limit|
          Timecop.freeze(approval_limit) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(approval_limit + 1.second) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
        (now + SS::Duration.parse(site.page_expiration_before)).tap do |publication_limit|
          Timecop.freeze(publication_limit) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.end_of_day) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.tomorrow.beginning_of_day) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
      end
    end

    context "with ever released page" do
      let(:item) do
        Timecop.freeze(now) { create(:article_page, cur_site: site, cur_node: node, state: "closed", first_released: now) }
      end

      it do
        @cur_site = site

        (now + SS::Duration.parse(site.approve_remind_later)).tap do |approval_limit|
          Timecop.freeze(approval_limit) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(approval_limit + 1.second) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
        (now + SS::Duration.parse(site.page_expiration_before)).tap do |publication_limit|
          Timecop.freeze(publication_limit) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.end_of_day) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.tomorrow.beginning_of_day) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
      end
    end

    context "with approval requested page" do
      let(:item) do
        Timecop.freeze(now) do
          create(
            :article_page, cur_site: site, cur_node: node, state: "closed", workflow_state: "request", workflow_comment: "",
            workflow_approvers: [{ level: 1, user_id: cms_user.id, state: "request", comment: "" }],
            workflow_required_counts: [ false ]
          )
        end
      end

      it do
        @cur_site = site

        (now + SS::Duration.parse(site.approve_remind_later)).tap do |approval_limit|
          Timecop.freeze(approval_limit) do
            css_class = %w(state state-request).join(" ")
            label = I18n.t("ss.state.request")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(approval_limit + 1.second) do
            css_class = %w(state state-request-remind).join(" ")
            label = [ I18n.t("ss.state.request"), I18n.t("workflow.state_remind_suffix") ].join
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
        (now + SS::Duration.parse(site.page_expiration_before)).tap do |publication_limit|
          Timecop.freeze(publication_limit) do
            css_class = %w(state state-request-remind).join(" ")
            label = [ I18n.t("ss.state.request"), I18n.t("workflow.state_remind_suffix") ].join
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.end_of_day) do
            css_class = %w(state state-request-remind).join(" ")
            label = [ I18n.t("ss.state.request"), I18n.t("workflow.state_remind_suffix") ].join
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.tomorrow.beginning_of_day) do
            css_class = %w(state state-request-remind).join(" ")
            label = [ I18n.t("ss.state.request"), I18n.t("workflow.state_remind_suffix") ].join
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
      end
    end

    context "with public node" do
      let(:item) do
        Timecop.freeze(now) { create(:category_node_page, cur_site: site, cur_node: node, state: "public") }
      end

      it do
        @cur_site = site

        (now + SS::Duration.parse(site.approve_remind_later)).tap do |approval_limit|
          Timecop.freeze(approval_limit) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(approval_limit + 1.second) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
        (now + SS::Duration.parse(site.page_expiration_before)).tap do |publication_limit|
          Timecop.freeze(publication_limit) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.end_of_day) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.tomorrow.beginning_of_day) do
            css_class = %w(state state-public).join(" ")
            label = I18n.t("ss.state.public")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
      end
    end

    context "with non-released node" do
      let(:item) do
        Timecop.freeze(now) { create(:category_node_page, cur_site: site, cur_node: node, state: "closed") }
      end

      it do
        @cur_site = site

        (now + SS::Duration.parse(site.approve_remind_later)).tap do |approval_limit|
          Timecop.freeze(approval_limit) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(approval_limit + 1.second) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
        (now + SS::Duration.parse(site.page_expiration_before)).tap do |publication_limit|
          Timecop.freeze(publication_limit) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.end_of_day) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.tomorrow.beginning_of_day) do
            css_class = %w(state state-edit).join(" ")
            label = I18n.t("ss.state.edit")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
      end
    end

    context "with ever released node" do
      let(:item) do
        Timecop.freeze(now) { create(:category_node_page, cur_site: site, cur_node: node, state: "closed", first_released: now) }
      end

      it do
        @cur_site = site

        (now + SS::Duration.parse(site.approve_remind_later)).tap do |approval_limit|
          Timecop.freeze(approval_limit) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(approval_limit + 1.second) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
        (now + SS::Duration.parse(site.page_expiration_before)).tap do |publication_limit|
          Timecop.freeze(publication_limit) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.end_of_day) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
          Timecop.freeze(publication_limit.tomorrow.beginning_of_day) do
            css_class = %w(state state-closed).join(" ")
            label = I18n.t("ss.state.closed")
            expect(helper.colored_state_label(item)).to eq "<span class=\"#{css_class}\">#{label}</span>"
          end
        end
      end
    end
  end
end
