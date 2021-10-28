require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:layout_html) do
    html = []
    html << "<html><body><div id=\"main\" class=\"page\">"
    html << "<header class=\"released\">\#{time.page_released.long}</header>"
    html << "{{ yield }}"
    html << "</div></body></html>"
    html
  end
  let!(:layout) { create :cms_layout, html: layout_html.join }
  let!(:node) { create :article_node_page, layout: layout }

  describe "#released_type" do
    let(:created) { Time.zone.now.beginning_of_minute - 2.weeks }
    let(:first_released) { created + 2.days }
    let(:released) { first_released + 2.days }
    let(:updated) { released + 3.days }
    let!(:item) { create :article_page, cur_node: node, state: "public" }

    before do
      item.set(created: created, first_released: first_released, released: released, updated: updated)
    end

    context "fixed is given" do
      it do
        item.released_type = "fixed"
        expect(item.date).to eq item.released
      end
    end

    context "same_as_updated is given" do
      it do
        item.released_type = "same_as_updated"
        expect(item.date).to eq item.updated
      end
    end

    context "same_as_created is given" do
      it do
        item.released_type = "same_as_created"
        expect(item.date).to eq item.created
      end
    end

    context "same_as_first_released is given" do
      it do
        item.released_type = "same_as_first_released"
        expect(item.date).to eq item.first_released
      end
    end

    context "illegally set to blank" do
      before do
        item.set(released_type: "")
      end

      context "default_released_type config set to same_as_updated" do
        before do
          @save_default_released_type = SS.config.cms.default_released_type
          SS.config.replace_value_at(:cms, :default_released_type, "same_as_updated")
          item.class.default_released_type = "same_as_updated"
        end

        after do
          SS.config.replace_value_at(:cms, :default_released_type, @save_default_released_type)
          item.class.default_released_type = @save_default_released_type
        end

        it do
          expect(item.date).to eq item.updated
        end
      end

      context "default_released_type config set to same_as_created" do
        before do
          @save_default_released_type = SS.config.cms.default_released_type
          SS.config.replace_value_at(:cms, :default_released_type, "same_as_created")
          item.class.default_released_type = "same_as_created"
        end

        after do
          SS.config.replace_value_at(:cms, :default_released_type, @save_default_released_type)
          item.class.default_released_type = @save_default_released_type
        end

        it do
          expect(item.date).to eq item.created
        end
      end

      context "default_released_type config set to fixed" do
        before do
          @save_default_released_type = SS.config.cms.default_released_type
          SS.config.replace_value_at(:cms, :default_released_type, "fixed")
          item.class.default_released_type = "fixed"
        end

        after do
          SS.config.replace_value_at(:cms, :default_released_type, @save_default_released_type)
          item.class.default_released_type = @save_default_released_type
        end

        it do
          expect(item.date).to eq item.released
        end
      end
    end
  end

  describe "published page" do
    let(:created) { Time.zone.now.beginning_of_minute - 2.weeks }
    let(:first_released) { created + 2.days }
    let(:released) { first_released + 2.days }
    let(:updated) { released + 3.days }

    shared_examples "publised page is" do
      let!(:item) do
        page = Timecop.freeze(created) do
          create(
            :article_page, cur_node: node, layout: layout,
            first_released: first_released, released: released, released_type: released_type,
            state: "closed"
          )
        end

        Timecop.freeze(first_released) do
          page.state = "public"
          page.save!
        end

        Timecop.freeze(released) do
          page.released = released
          page.save!
        end

        Timecop.freeze(updated) do
          page.html = "<p>hello, world!</p>"
          page.save!
        end

        page
      end

      it do
        expect(item.created).to eq created
        expect(item.updated).to eq updated
        expect(item.first_released).to eq first_released
        case released_type
        when "same_as_updated"
          expect(item.released).to eq updated
        when "same_as_created"
          expect(item.released).to eq created
        when "same_as_first_released"
          expect(item.released).to eq first_released
        else # fixed
          expect(item.released).to eq released
        end

        html = ::File.read(item.path)
        html.include?(expected_date)
      end
    end

    context "fixed is given" do
      let(:released_type) { "fixed" }
      let(:expected_date) { I18n.l(released.to_date, format: :long) }

      it_behaves_like "publised page is"
    end

    context "same_as_updated is given" do
      let(:released_type) { "same_as_updated" }
      let(:expected_date) { I18n.l(updated.to_date, format: :long) }

      it_behaves_like "publised page is"
    end

    context "same_as_created is given" do
      let(:released_type) { "same_as_created" }
      let(:expected_date) { I18n.l(created.to_date, format: :long) }

      it_behaves_like "publised page is"
    end

    context "same_as_first_released is given" do
      let(:released_type) { "same_as_first_released" }
      let(:expected_date) { I18n.l(first_released.to_date, format: :long) }

      it_behaves_like "publised page is"
    end
  end
end
