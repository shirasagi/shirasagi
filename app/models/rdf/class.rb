class Rdf::Class
  extend SS::Translation
  include SS::Document
  include Rdf::Object

  field :sub_class_of, type: String
  field :properties, type: Array

  permit_params :sub_class_of, :properties
  permit_params properties: ["property", "class", "cardinality", "comments", {comments: %w(ja en invariant)}]

  def expand_properties(check = {})
    ret = expand_super_class_properties(check)

    # check whether already flatterned.
    iri = "#{vocab.uri}#{name}"
    return ret if check.key?(iri)

    check[iri] = true
    return ret if properties.blank?

    properties.each do |prop|
      klass = find_class(prop["class"])
      tmp = klass.present? ? klass.expand_properties : nil
      ret << ["#{self.vocab.prefix}:#{prop["property"]}", Rdf::Vocab.pname(prop["class"]), find_lang_string(prop["comments"]), tmp]
    end
    ret
  end

  def flattern_properties
    properties = expand_properties
    return properties if properties.blank?
    flattern_properties_recursive(properties)
  end

  private
    def expand_super_class_properties(check)
      return [] if sub_class_of.blank?

      sub_class = find_class(sub_class_of)
      sub_class.present? ? sub_class.expand_properties(check) : []
    end

    def flattern_properties_recursive(roots)
      ret = []
      roots.each do |name, klass, comment, sub_props|
        if sub_props.present?
          flat_sub_props = flattern_properties_recursive(sub_props)
          flat_sub_props.each do |flat_sub_prop|
            flat_sub_prop[:names].insert(0, name.split(':')[1])
            flat_sub_prop[:properties].insert(0, name)
            flat_sub_prop[:classes].insert(0, klass)
            flat_sub_prop[:comments].insert(0, comment)
          end
          ret.concat(flat_sub_props)
        else
          ret << { names: [name.split(':')[1]],
                   properties: [name],
                   classes: [klass],
                   comments: [comment]}
        end
      end
      ret
    end

    def find_class(class_uri)
      prefix, name = Rdf::Vocab.qname(class_uri)
      vocab = Rdf::Vocab.site(self.vocab.site).where(prefix: prefix).first
      klass = Rdf::Class.vocab(vocab).where(name: name).first if vocab.present?
      klass
    end

    def find_lang_string(hash)
      hash.try(:[], "ja") || hash.try(:[], "en") || hash.try(:[], "invariant")
    end
end
