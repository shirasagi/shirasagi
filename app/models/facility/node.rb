module Facility::Node
  class Base
    include Cms::Model::Node
    include Cms::Addon::NodeSetting

    default_scope ->{ where(route: /^facility\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Facility::Addon::CategorySetting
    include Facility::Addon::ServiceSetting
    include Facility::Addon::LocationSetting
    include Facility::Addon::OpendataAssoc
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Facility::Addon::Body
    include Cms::Addon::AdditionalInfo
    include Facility::Addon::Category
    include Facility::Addon::Service
    include Facility::Addon::Location
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/page") }

    def serve_static_file?
      false
    end

    COLUMNS = %w(
      filename name layout kana address postcode tel
      fax related_url categories locations services
      map_points groups
    ).freeze

    PUBLIC_COLUMNS = %w(
      name kana address postcode tel
      fax related_url categories locations services
      map_points
    ).freeze

    class << self
      def to_csv(opts = {})
        t_columns = (opts[:public] ? PUBLIC_COLUMNS : COLUMNS).map { |c| t(c) }
        additional_columns = criteria.map { |item| item.additional_info.map { |i| i[:field] } }.flatten.compact.uniq

        CSV.generate do |data|
          data << t_columns + additional_columns.map { |c| "#{self.t(:additional_info)}:#{c}" }
          criteria.each do |item|
            data << attributes_to_row(item, additional_columns, opts)
          end
        end
      end

      private
        def attributes_to_row(item, additional_columns, opts)
          maps = Facility::Map.site(item.site).where(filename: /^#{item.filename}\//, depth: item.depth + 1)
          points = maps.map{ |m| m.map_points }.flatten.map{ |m| m[:loc].join(",") }

          row = []
          row << item.basename unless opts[:public]
          row << item.name
          row << item.layout.try(:name) unless opts[:public]
          row << item.kana
          row << item.address
          row << item.postcode
          row << item.tel
          row << item.fax
          row << item.related_url
          row << item.categories.map(&:name).join("\n")
          row << item.locations.map(&:name).join("\n")
          row << item.services.map(&:name).join("\n")
          row << points.join("\n")
          row << item.groups.pluck(:name).join("\n") unless opts[:public]
          additional_columns.each do |c|
            row << item.additional_info.map { |i| [i[:field], i[:value]] }.to_h[c]
          end
          row
        end
    end
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Facility::Addon::CategorySetting
    include Facility::Addon::ServiceSetting
    include Facility::Addon::LocationSetting
    include Facility::Addon::SearchSetting
    include Facility::Addon::SearchResult
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/search") }

    def condition_hash
      cond = []

      cond << { filename: /^#{filename}\// } if conditions.blank?
      conditions.each do |url|
        s = cur_site || site rescue nil
        node = Cms::Node.site(s).filename(url).first
        next unless node
        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
      end

      { '$or' => cond }
    end
  end

  class Category
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Facility::Addon::IconSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/category") }

    def condition_hash
      cond = []
      cids = []

      cids << id
      conditions.each do |url|
        s = cur_site || site rescue nil
        node = Cms::Node.site(s).filename(url).first
        next unless node
        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :category_ids.in => cids } if cids.present?

      { '$or' => cond }
    end
  end

  class Service
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/service") }

    def condition_hash
      cond = []
      cids = []

      cids << id
      conditions.each do |url|
        s = cur_site || site rescue nil
        node = Cms::Node.site(s).filename(url).first
        next unless node
        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :service_ids.in => cids } if cids.present?

      { '$or' => cond }
    end
  end

  class Location
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Facility::Addon::FocusSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "facility/location") }

    def condition_hash
      cond = []
      cids = []

      cids << id
      conditions.each do |url|
        s = cur_site || site rescue nil
        node = Cms::Node.site(s).filename(url).first
        next unless node
        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :location_ids.in => cids } if cids.present?

      { '$or' => cond }
    end
  end
end
