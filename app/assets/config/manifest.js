// webpacker で生成するアセットを明示的に指定する。指定していないと Sprockets 4 からエラーになる。
//
//= link application.js
//= link application.css
//= link colorbox.js
//= link colorbox.css
//= link jplayer.js
//= link jplayer.css

// ビルドするアセット一覧（アルファベット順）
// 次のコマンドで、一覧を生成することができる
// find app/assets -name '*.js*' -o -name '*.css*' -o -name '*.scss*' | \
//   fgrep -v app/assets/builds/ | \
//   fgrep -v app/assets/config/ | \
//   fgrep -v "/lib/" | \
//   fgrep -v "/_" | \
//   sort | \
//   sed -e 's#app/assets/javascripts/##' | \
//   sed -e 's#app/assets/stylesheets/##' | \
//   sed -e 's#\.erb##' | \
//   sed -e 's#\.scss#.css#'

// javascript

//= link board/script.js
//= link cms/compat.js
//= link cms/form_db.js
//= link cms/preview/datatables.js
//= link cms/preview/datetimepicker.js
//= link cms/preview/jquery-ui.js
//= link cms/preview/jquery.js
//= link cms/preview/main.js
//= link cms/public.js
//= link gws/affair/menu.js
//= link gws/affair/overtime_file.js
//= link gws/affair/shift_records.js
//= link gws/attendance/attendance.js
//= link gws/attendance/portlet.js
//= link gws/calendar.js
//= link gws/discussion/thread.js
//= link gws/elasticsearch/highlighter.js
//= link gws/memo/filter.js
//= link gws/memo/folder.js
//= link gws/memo/message.js
//= link gws/presence/user.js
//= link gws/script.js
//= link gws/share/folder_toolbar.js
//= link inquiry/chart.js
//= link map/googlemaps/facility/search.js
//= link map/googlemaps/form.js
//= link map/googlemaps/map.js
//= link map/googlemaps/member/photo/form.js
//= link map/lgwan/form.js
//= link map/openlayers/facility/search.js
//= link map/openlayers/form.js
//= link map/openlayers/map.js
//= link map/openlayers/member/photo/form.js
//= link map/openlayers/opendata/dataset_map.js
//= link map/reference.js
//= link member/public.js
//= link opendata/dataset_graph.js
//= link opendata/form.js
//= link opendata/graph.js
//= link opendata/opendata.js
//= link opendata/public.js
//= link ss/chart.js
//= link ss/chartjs-colorschemes.js
//= link ss/debug.js
//= link ss/script.js

// css / scss

//= link cms/form_db.css
//= link cms/mobile.css
//= link cms/preview/ajax_in_iframe.css
//= link cms/preview/datatables.css
//= link cms/preview/datetimepicker.css
//= link cms/preview/jquery-ui.css
//= link cms/preview/jquery.css
//= link cms/preview/main.css
//= link cms/public.css
//= link gws/style.css
//= link member/public.css
//= link opendata/form.css
//= link ss/cke.css
//= link ss/cke_reset.css
//= link ss/print.css
//= link ss/style.css

// others like image

//= link opendata/icon-user.png
