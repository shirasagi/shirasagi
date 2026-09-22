const path = require("path")
const webpack = require("webpack")
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const RemoveEmptyScriptsPlugin = require('webpack-remove-empty-scripts')
const { CleanWebpackPlugin } = require('clean-webpack-plugin')
const Config = require("./webpack/config")
const i18nextResourceGen = require("./webpack/i18next_resource_generator")
const RAILS_ENV = process.env.RAILS_ENV || Config.environment.RAILS_ENV

module.exports = {
  mode: RAILS_ENV === "production" ? "production" : "development",
  // see: https://webpack.js.org/configuration/devtool/
  devtool: [
    { type: "all", use: RAILS_ENV === "production" ? "source-map" : "eval-source-map" }
  ],
  entry: {
    application: "./app/javascript/application.js",
    choices: "./app/javascript/choices.js",
    colorbox: "./app/javascript/colorbox.js",
    swiper: "./app/javascript/swiper.js",
    jplayer: "./app/javascript/jplayer.js",
    // legacy scripts
    "board/script": "./app/assets/javascripts/board/script.js",
    "cms/compat": "./app/assets/javascripts/cms/compat.js",
    "cms/form_db": "./app/assets/javascripts/cms/form_db.js",
    "cms/preview/datatables": "./app/assets/javascripts/cms/preview/datatables.js",
    "cms/preview/datetimepicker": "./app/assets/javascripts/cms/preview/datetimepicker.js",
    "cms/preview/jquery-ui": "./app/assets/javascripts/cms/preview/jquery-ui.js",
    "cms/preview/jquery": "./app/assets/javascripts/cms/preview/jquery.js",
    "cms/preview/main": "./app/assets/javascripts/cms/preview/main.js",
    "cms/public": "./app/assets/javascripts/cms/public.js",
    "gws/affair/menu": "./app/assets/javascripts/gws/affair/menu.js",
    "gws/affair/overtime_file": "./app/assets/javascripts/gws/affair/overtime_file.js",
    "gws/affair/shift_records": "./app/assets/javascripts/gws/affair/shift_records.js",
    "gws/attendance/attendance": "./app/assets/javascripts/gws/attendance/attendance.js",
    "gws/attendance/portlet": "./app/assets/javascripts/gws/attendance/portlet.js",
    "gws/calendar": "./app/assets/javascripts/gws/calendar.js",
    "gws/discussion/thread": "./app/assets/javascripts/gws/discussion/thread.js",
    "gws/elasticsearch/highlighter": "./app/assets/javascripts/gws/elasticsearch/highlighter.js",
    "gws/memo/filter": "./app/assets/javascripts/gws/memo/filter.js",
    "gws/memo/folder": "./app/assets/javascripts/gws/memo/folder.js",
    "gws/memo/message": "./app/assets/javascripts/gws/memo/message.js",
    "gws/presence/user": "./app/assets/javascripts/gws/presence/user.js",
    "gws/script": "./app/assets/javascripts/gws/script.js",
    "gws/share/folder_toolbar": "./app/assets/javascripts/gws/share/folder_toolbar.js",
    "inquiry/chart": "./app/assets/javascripts/inquiry/chart.js",
    "map/googlemaps/facility/search": "./app/assets/javascripts/map/googlemaps/facility/search.js",
    "map/googlemaps/form": "./app/assets/javascripts/map/googlemaps/form.js",
    "map/googlemaps/map": "./app/assets/javascripts/map/googlemaps/map.js",
    "map/googlemaps/member/photo/form": "./app/assets/javascripts/map/googlemaps/member/photo/form.js",
    "map/lgwan/form": "./app/assets/javascripts/map/lgwan/form.js",
    "map/openlayers/facility/search": "./app/assets/javascripts/map/openlayers/facility/search.js",
    "map/openlayers/form": "./app/assets/javascripts/map/openlayers/form.js",
    "map/openlayers/map": "./app/assets/javascripts/map/openlayers/map.js",
    "map/openlayers/member/photo/form": "./app/assets/javascripts/map/openlayers/member/photo/form.js",
    "map/openlayers/opendata/dataset_map": "./app/assets/javascripts/map/openlayers/opendata/dataset_map.js",
    "map/reference": "./app/assets/javascripts/map/reference.js",
    "member/public": "./app/assets/javascripts/member/public.js",
    "opendata/dataset_graph": "./app/assets/javascripts/opendata/dataset_graph.js",
    "opendata/form": "./app/assets/javascripts/opendata/form.js",
    "opendata/graph": "./app/assets/javascripts/opendata/graph.js",
    "opendata/opendata": "./app/assets/javascripts/opendata/opendata.js",
    "opendata/public": "./app/assets/javascripts/opendata/public.js",
    "ss/chart": "./app/assets/javascripts/ss/chart.js",
    "ss/chartjs-colorschemes": "./app/assets/javascripts/ss/chartjs-colorschemes.js",
    "ss/debug": "./app/assets/javascripts/ss/debug.js",
    "ss/script": "./app/assets/javascripts/ss/script.js",
  },
  externals: [
    {
      $: "jquery",
      jquery: 'jQuery',
    }
  ],
  module: {
    rules: [
      {
        test: /\.(sa|sc|c)ss$/i,
        use: [
          MiniCssExtractPlugin.loader,
          { loader: 'css-loader', options: { sourceMap: true } },
          { loader: 'postcss-loader', options: { sourceMap: true } },
          { loader: 'sass-loader', options: { sourceMap: true } }
        ]
      },
      {
        test: /\.(png|jpe?g|gif|svg|eot|ttf|woff|woff2)$/i,
        type: "asset",
        parser: {
          dataUrlCondition: {
            maxSize: 16 * 1024 // 16kb
          }
        }
      }
    ]
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map[query]",
    path: path.resolve(__dirname, "app/assets/builds"),
  },
  plugins: [
    new webpack.DefinePlugin({
      RAILS_ENV: JSON.stringify(RAILS_ENV),
      AVAILABLE_LOCALES: JSON.stringify(Config.environment.available_locales),
      I18NEXT_RESOURCES: JSON.stringify(RAILS_ENV === "production" ? i18nextResourceGen.generate() : {}),
      DEFAULT_SWATCHES: JSON.stringify(Config.minicolors_swatches[RAILS_ENV]?.color_codes),
      // API KEY などが漏洩しないようにホワイトリスト方式でエクスポートする
      MAP_CONFIG_EXPORTS: JSON.stringify({
        map_center: Config.map[RAILS_ENV]?.map_center,
        map_marker_images: Config.map[RAILS_ENV]?.map_marker_images,
        googlemaps_zoom_level: Config.map[RAILS_ENV]?.googlemaps_zoom_level,
        googlemaps_search_end_point: Config.map[RAILS_ENV]?.googlemaps_search_end_point,
        openlayers_zoom_level: Config.map[RAILS_ENV]?.openlayers_zoom_level
      }),
      OPENDATA_AVAILABLE_RESOURCE_FORMATS_CONFIG: JSON.stringify(Config.opendata[RAILS_ENV].available_resource_formats),
      // API KEY などが漏洩しないようにホワイトリスト方式でエクスポートする
      SS_CONFIG_EXPORTS: JSON.stringify({
        dc_guard_timeout_millis: Config.ss[RAILS_ENV]?.dc_guard_timeout_millis,
        notice: { timeout_delay: Config.ss[RAILS_ENV]?.notice?.timeout_delay }
      }),
      KANA_CONFIG_EXPORTS: JSON.stringify({
        location: Config.kana[RAILS_ENV]?.location
      }),
      TRANSLATE_CONFIG_EXPORTS: JSON.stringify({
        location: Config.translate[RAILS_ENV]?.location
      }),
      VOICE_CONFIG_EXPORTS: JSON.stringify({
        controller: {
          location: Config.voice[RAILS_ENV]?.controller?.location
        },
        resource: {
          loading: Config.voice[RAILS_ENV]?.resource?.loading,
          disabled: Config.voice[RAILS_ENV]?.resource?.disabled,
          overload: Config.voice[RAILS_ENV]?.resource?.overload,
          jplayer_path: Config.voice[RAILS_ENV]?.resource?.jplayer_path
        }
      })
    }),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new CleanWebpackPlugin({
      cleanOnceBeforeBuildPatterns: [ "**/*.js", "**/*.css" ]
    }),
    new RemoveEmptyScriptsPlugin(),
    new MiniCssExtractPlugin({
      filename: "[name].css"
    }),
    new webpack.NormalModuleReplacementPlugin(
      /^node:/,
      (resource) => { resource.request = resource.request.replace(/^node:/, ''); })
  ],
  resolve: {
    fallback: {
      fs: false,
      path: false
    }
  }
}
