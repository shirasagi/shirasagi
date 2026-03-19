module Cms::CheckLinks
  Link = Data.define(:full_url, :href, :line, :type, :rel, :ss_rel) do
    def meta
      { line: line, inner_yield: type == :inner_yield }
    end

    def nofollow?
      return true if rel && rel.include?("nofollow")
      return true if ss_rel && ss_rel.include?("nofollow")
      false
    end
  end

  LinkWithSource = Data.define(:source, :link) do
    delegate :full_url, :status, to: :source
    delegate :href, :line, :type, :meta, :nofollow?, to: :link
  end
end
