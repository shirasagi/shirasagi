require 'spec_helper'

describe Cms::Apis::GroupDropdownTreeComponent, type: :component, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:user0) { cms_user }
  let!(:root_group) { create :cms_group, name: unique_id }
  let!(:site) { create :cms_site_unique, group_ids: [ root_group.id ] }
  let(:now) { Time.zone.now.change(usec: 0) }

  before do
    @cache_read_events = []
    @cache_read_subscriber = ActiveSupport::Notifications.subscribe("cache_read.active_support") do |*args|
      @cache_read_events << ActiveSupport::Notifications::Event.new(*args)
    end

    @cache_write_events = []
    @cache_write_subscriber = ActiveSupport::Notifications.subscribe("cache_write.active_support") do |*args|
      @cache_write_events << ActiveSupport::Notifications::Event.new(*args)
    end

    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = perform_caching

    create(:cms_group, name: "#{root_group.name}/BBB")
    create(:cms_group, name: "#{root_group.name}/CCC", order: 30)
    create(:cms_group, name: "#{root_group.name}/BBB/DDDD", order: 40)
    create(:cms_group, name: "#{root_group.name}/BBB/EEEE", order: 70)
    create(:cms_group, name: "#{root_group.name}/CCC/FFFF", order: 50)
    create(:cms_group, name: "#{root_group.name}/CCC/GGGG", order: 60)
    # lost child
    create(:cms_group, name: "#{root_group.name}/HHH/IIII", order: 0)
  end

  after do
    described_class.perform_caching = @save_perform_caching

    ActiveSupport::Notifications.unsubscribe(@cache_read_subscriber)
    ActiveSupport::Notifications.unsubscribe(@cache_write_subscriber)
    Rails.cache.clear
  end

  context "when caching is enabled" do
    let(:perform_caching) { true }

    it do
      Timecop.freeze(now) do
        described_class.new(cur_site: site).tap do |component|
          expect(component.cache_exist?).to be_falsey

          html = render_inline component
          html.css("a[data-id='#{root_group.id}']").tap do |anchor|
            expect(anchor).to have(1).items
            expect(anchor.to_html).to include(root_group.trailing_name)
          end
          root_group.descendants_and_self.each do |group|
            html.css("a[data-id='#{group.id}']").tap do |anchor|
              expect(anchor).to have(1).items
              expect(anchor.to_html).to include(group.trailing_name)
            end
          end

          expect(component.cache_exist?).to be_truthy
          expect(@cache_read_events).to have(1).items
          expect(@cache_write_events).to have(1).items
        end
      end

      Timecop.freeze(now + 1.day - 1.second) do
        described_class.new(cur_site: site).tap do |component|
          html = render_inline component
          html.css("a[data-id='#{root_group.id}']").tap do |anchor|
            expect(anchor).to have(1).items
            expect(anchor.to_html).to include(root_group.trailing_name)
          end
          root_group.descendants_and_self.each do |group|
            html.css("a[data-id='#{group.id}']").tap do |anchor|
              expect(anchor).to have(1).items
              expect(anchor.to_html).to include(group.trailing_name)
            end
          end

          expect(component.cache_exist?).to be_truthy
          expect(@cache_read_events).to have(2).items
          expect(@cache_write_events).to have(1).items
        end
      end

      Timecop.freeze(now + 1.day) do
        # cache was expired
        described_class.new(cur_site: site).tap do |component|
          expect(component.cache_exist?).to be_falsey

          html = render_inline component
          html.css("a[data-id='#{root_group.id}']").tap do |anchor|
            expect(anchor).to have(1).items
            expect(anchor.to_html).to include(root_group.trailing_name)
          end
          root_group.descendants_and_self.each do |group|
            html.css("a[data-id='#{group.id}']").tap do |anchor|
              expect(anchor).to have(1).items
              expect(anchor.to_html).to include(group.trailing_name)
            end
          end

          expect(component.cache_exist?).to be_truthy
          expect(@cache_read_events).to have(3).items
          expect(@cache_write_events).to have(2).items
        end

        # new group added
        create(:gws_group, name: "#{root_group.name}/#{unique_id}")

        described_class.new(cur_site: site).tap do |component|
          expect(component.cache_exist?).to be_falsey

          html = render_inline component
          html.css("a[data-id='#{root_group.id}']").tap do |anchor|
            expect(anchor).to have(1).items
            expect(anchor.to_html).to include(root_group.trailing_name)
          end
          root_group.descendants_and_self.each do |group|
            html.css("a[data-id='#{group.id}']").tap do |anchor|
              expect(anchor).to have(1).items
              expect(anchor.to_html).to include(group.trailing_name)
            end
          end

          expect(component.cache_exist?).to be_truthy
          expect(@cache_read_events).to have(4).items
          expect(@cache_write_events).to have(3).items
        end
      end
    end
  end

  context "when caching is disabled" do
    let(:perform_caching) { false }

    it do
      Timecop.freeze(now) do
        described_class.new(cur_site: site).tap do |component|
          expect(component.cache_exist?).to be_falsey

          html = render_inline component
          html.css("a[data-id='#{root_group.id}']").tap do |anchor|
            expect(anchor).to have(1).items
            expect(anchor.to_html).to include(root_group.trailing_name)
          end
          root_group.descendants_and_self.each do |group|
            html.css("a[data-id='#{group.id}']").tap do |anchor|
              expect(anchor).to have(1).items
              expect(anchor.to_html).to include(group.trailing_name)
            end
          end

          expect(component.cache_exist?).to be_falsey
          expect(@cache_read_events).to have(0).items
          expect(@cache_write_events).to have(0).items
        end
      end

      Timecop.freeze(now + 1.day - 1.second) do
        described_class.new(cur_site: site).tap do |component|
          html = render_inline component
          html.css("a[data-id='#{root_group.id}']").tap do |anchor|
            expect(anchor).to have(1).items
            expect(anchor.to_html).to include(root_group.trailing_name)
          end
          root_group.descendants_and_self.each do |group|
            html.css("a[data-id='#{group.id}']").tap do |anchor|
              expect(anchor).to have(1).items
              expect(anchor.to_html).to include(group.trailing_name)
            end
          end

          expect(component.cache_exist?).to be_falsey
          expect(@cache_read_events).to have(0).items
          expect(@cache_write_events).to have(0).items
        end
      end

      Timecop.freeze(now + 1.day) do
        # cache was expired
        described_class.new(cur_site: site).tap do |component|
          expect(component.cache_exist?).to be_falsey

          html = render_inline component
          html.css("a[data-id='#{root_group.id}']").tap do |anchor|
            expect(anchor).to have(1).items
            expect(anchor.to_html).to include(root_group.trailing_name)
          end
          root_group.descendants_and_self.each do |group|
            html.css("a[data-id='#{group.id}']").tap do |anchor|
              expect(anchor).to have(1).items
              expect(anchor.to_html).to include(group.trailing_name)
            end
          end

          expect(component.cache_exist?).to be_falsey
          expect(@cache_read_events).to have(0).items
          expect(@cache_write_events).to have(0).items
        end
      end
    end
  end
end
