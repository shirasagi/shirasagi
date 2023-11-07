class Cms::SyntaxChecker::InternalLinkChecker
  include Cms::SyntaxChecker::Base

  ATTRIBUTES = %w(href src).freeze

  def check(context, id, idx, raw_html, fragment)
    ATTRIBUTES.each do |attr|
      fragment.css("[#{attr}]").each do |node|
        attr_value = node[attr]
        next if attr_value.blank?

        url = ::Addressable::URI.parse(attr_value) rescue nil
        next if !url || !internal_link?(context, url)

        if url.scheme.present? || url.host.present?
          add_error(context, id, idx, node, :internal_link_shouldnt_contain_domains)
        elsif url.path.present?
          if !url.path.start_with?("/")
            add_error(context, id, idx, node, :internal_link_should_be_absolute_path)
          elsif url.path.start_with?("/.s#{context.cur_site.id}/preview/")
            add_error(context, id, idx, node, :internal_link_shouldnt_be_preview_path)
          end
        end
      end
    end
  end

  private

  def add_error(context, id, idx, node, error)
    context.errors << {
      id: id,
      idx: idx,
      code: Cms::SyntaxChecker::Base.outer_html_summary(node),
      msg: I18n.t("errors.messages.#{error}"),
      detail: I18n.t("errors.messages.syntax_check_detail.#{error}"),
    }
  end

  def internal_link?(context, url)
    domain = url.host
    if domain.present?
      return context.cur_site.domains.any? do |site_domain|
        next true if domain == site_domain
        next true if domain.sub(/:.*$/, "") == site_domain.sub(/:.*$/, "")
        false
      end
    end

    # domain is blank like mailto:, tel:, or something
    url.scheme.blank?
  end
end
