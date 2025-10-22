class Cms::SyntaxChecker::InternalLinkChecker
  include Cms::SyntaxChecker::Base

  ATTRIBUTES = %w(href src).freeze

  def check(context, content)
    ATTRIBUTES.each do |attr|
      context.fragment.css("[#{attr}]").each do |node|
        attr_value = node[attr]
        next if attr_value.blank?

        url = ::Addressable::URI.parse(attr_value) rescue nil
        next if !url || !internal_link?(context, url)

        if url.scheme.present? || url.host.present?
          add_error(context, content, node, :internal_link_shouldnt_contain_domains)
        elsif url.path.present?
          if !url.path.start_with?("/")
            add_error(context, content, node, :internal_link_should_be_absolute_path)
          elsif url.path.start_with?("/.s#{context.cur_site.id}/preview/")
            add_error(context, content, node, :internal_link_shouldnt_be_preview_path)
          end
        end
      end
    end
  end

  private

  def add_error(context, content, node, error)
    code = Cms::SyntaxChecker::Base.outer_html_summary(node)
    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: error)
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
