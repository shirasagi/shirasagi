module Cms::CheckLinks
  Link = Data.define(:full_url, :href, :line, :type, :rel, :ss_rel) do
    def meta
      { line: line, inner_yield: type == :inner_yield }
    end
  end

  LinkWithSource = Data.define(:source, :link) do
    delegate :full_url, :status, to: :source
    delegate :href, :line, :type, :meta, to: :link
  end
end
