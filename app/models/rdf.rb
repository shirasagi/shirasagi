module Rdf
  module_function

  def normalize_name(name)
    return if name.nil?
    # remove non-printable characters such as null char(\x00)
    name = name.gsub(/[^[:print:]]/i, '')
    # name must be NFKC
    UNF::Normalizer.normalize(name, :nfkc).strip
  end
end
