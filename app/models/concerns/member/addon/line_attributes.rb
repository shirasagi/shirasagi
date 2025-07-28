module Member::Addon
  module LineAttributes
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :first_registered, type: DateTime
      field :subscribe_line_message, type: String, default: "active"
      embeds_ids :deliver_categories, class_name: "Cms::Line::DeliverCategory::Base"
      field :subscribe_richmenu_id, type: String

      validates :subscribe_line_message, inclusion: { in: %w(active expired) }

      permit_params :first_registered, :subscribe_richmenu_id, :subscribe_line_message
      permit_params deliver_category_ids: []
    end

    def each_deliver_categories
      Cms::Line::DeliverCategory::Base.site(site).each_public do |root, children|
        categories = children.select { |child| deliver_category_ids.include?(child.id) }
        yield(root, categories)
      end
    end

    def deliver_category_conditions
      @_deliver_category_conditions ||= begin
        cond = []
        each_deliver_categories do |root, children|
          st_category_ids = children.map(&:st_category_ids).flatten
          st_category_ids << -1 if st_category_ids.blank?
          cond << { category_ids: { "$in" => st_category_ids } }
        end
        cond.present? ? { "$and" => cond } : { id: -1 }
      end
    end

    def subscribe_line_message_options
      %w(active expired).map { |m| [ I18n.t("member.options.subscribe_line_message.#{m}"), m ] }.to_a
    end

    def private_show_path(*args)
      options = args.extract_options!
      options.merge!(site: (cur_site || site), id: id)
      helper_mod = Rails.application.routes.url_helpers
      helper_mod.cms_member_path(*args, options) rescue nil
    end

    module ClassMethods
      def encode_sjis(str)
        str.encode("SJIS", invalid: :replace, undef: :replace)
      end

      def line_members_enum(site)
        members = criteria.to_a

        roots = []
        category_ids = []
        Cms::Line::DeliverCategory::Base.site(site).each_public do |root, children|
          roots << root
          category_ids << children.map(&:id)
        end

        Enumerator.new do |y|
          headers = %w(id name oauth_id).map { |v| self.t(v) }
          headers += roots.map(&:name)
          y << encode_sjis(headers.to_csv)
          members.each do |item|
            row = []
            row << item.id
            row << item.name
            row << item.oauth_id
            category_ids.each do |ids|
              row << item.deliver_categories.select { |category| ids.include?(category.id) }.map(&:name).join("\n")
            end
            y << encode_sjis(row.to_csv)
          end
        end
      end
    end
  end
end
