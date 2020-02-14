module Member::Addon::Photo::Search
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    def condition_hash(opts = {})
      cond = []
      cids = []

      conditions.each do |url|
        # regex
        if url =~ /\/\*$/
          filename = url.sub(/\/\*$/, "")
          cond << { filename: /^#{filename}\// }
          next
        end

        node = Cms::Node.site(cur_site || site).filename(url).first rescue nil
        next unless node

        cond << { filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :category_ids.in => cids } if cids.present?
      return {} if cond.blank?

      { '$or' => cond }
    end

    def sort_options
      [
        [I18n.t('cms.options.sort.name'), 'name'],
        [I18n.t('cms.options.sort.filename'), 'filename'],
        [I18n.t('cms.options.sort.created'), 'created'],
        [I18n.t('cms.options.sort.updated_1'), 'updated -1'],
        [I18n.t('cms.options.sort.released_1'), 'released -1'],
        [I18n.t('cms.options.sort.order'), 'order'],
      ]
    end

    def sort_hash
      return { released: -1 } if sort.blank?
      { sort.sub(/ .*/, "") => (/-1$/.match?(sort) ? -1 : 1) }
    end
  end
end
