json.html(@result)
json.intentId(@intent.try(:id))
json.suggests(@suggest.presence)
if @intent.present?
  json.question(@cur_node.becomes_with_route.question)
  json.chatSuccess(I18n.t('chat.options.question.success'))
  json.chatRetry(I18n.t('chat.options.question.retry'))
end
if @site_search_node.present?
  uri = URI.parse(@site_search_node.url)
  uri.query = { s: { keyword: params[:text] } }.to_query
  json.siteSearchUrl(uri.to_s)
  json.siteSearchText(I18n.t('chat.links.open_site_search'))
end
