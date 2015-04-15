module Opendata::Csv2rdfSettingsHelper
  def prev_url
    wid = Opendata::Csv2rdfSettingsController::ACTION_SEQUENCE.index(params[:action].to_sym)
    if wid.nil? || wid == 0
      url_for(controller: :resources, action: :show, id: @cur_resource)
    else
      url_for(action: Opendata::Csv2rdfSettingsController::ACTION_SEQUENCE[wid - 1])
    end
  end

  def next_url?
    wid = Opendata::Csv2rdfSettingsController::ACTION_SEQUENCE.index(params[:action].to_sym)
    if wid.nil? || wid == 0
      true
    else
      wid + 1 < Opendata::Csv2rdfSettingsController::ACTION_SEQUENCE.length
    end
  end

  def vocab_options
    return @vocab_options if @vocab_options

    vocabs = Rdf::Vocab.site(@cur_site).each.select do |vocab|
      vocab.allowed?(:read, @cur_user, site: @cur_site)
    end
    @vocab_options = vocabs.reduce([]) do |ret, vocab|
      ret << [ vocab.labels.preferred_value, vocab.id ]
    end.to_a
  end

  def classes
    @classes ||= Rdf::Class.site(@cur_site).search(params[:s]).page(params[:page]).per(50)
  end

  def tsv
    @tsv ||= @cur_resource.parse_tsv
  end

  def unmapped_headers
    return @unmapped_headers if @unmapped_headers
    @unmapped_headers = @item.column_types.map.with_index do |column_type, column_index|
      if column_type["properties"] || column_type[:properties]
        nil
      else
        label = @item.header_labels[column_index].join
        klasses = column_type["classes"]
        klasses = column_type[:classes] if klasses.blank?

        [ label, klasses.first ]
      end
    end
    @unmapped_headers.compact!
    @unmapped_headers
  end

  def each_expand_properties(props = @rdf_class.expand_properties, depth = 0, ids = [], names = [], classes = [], &block)
    props.each do |id, name, klass, comment, sub_props|
      ids << id
      names << name
      classes << klass
      yield id, name, klass, comment, sub_props, depth, ids, names, classes
      each_expand_properties(sub_props, depth + 1, ids, names, classes, &block) if sub_props.present?
      names.delete_at(-1)
      classes.delete_at(-1)
    end
  end

  def property_label_at(column_index)
    properties = @item.column_types[column_index]["properties"] || @item.column_types[column_index][:properties]
    if properties.blank?
      if @item.column_types[column_index]["classes"].first == false
        property_label = "無視列"
      else
        property_label = "ファイル固有"
      end
    else
      property_label = properties.join("\n")
    end
    property_label
  end

  def find_header_labels(properties)
    found = nil
    @item.column_types.each_with_index do |column_type, index|
      x = column_type["properties"] || column_type[:properties]
      next if x.blank?

      if x == properties
        found = index
        break
      end
    end

    return nil unless found
    @item.header_labels[found].join
  end
end
