class SS::DataUrl
  class MalformedDataUrlError < ::StandardError; end

  class << self
    def decode(data_url)
      # data_url ::= 'data:' [ mediatype ] [ ';' 'base64' ] ',' data
      # mediatype ::= top_level_type_name '/' subtype_name [ ';' parameters ]
      raise MalformedDataUrlError unless data_url.start_with?('data:')
      data_index = data_url.index(',', 5)
      raise MalformedDataUrlError unless data_index

      media_type = data_url[5..data_index - 1]
      data = data_url[data_index + 1..-1]

      media_type_options = media_type.split(';')
      media_type = media_type_options.shift

      if media_type_options.include?('base64')
        [ media_type, media_type_options, Base64.decode64(data) ]
      else
        [ media_type, media_type_options, data ]
      end
    end
  end
end
