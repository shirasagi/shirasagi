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
    "opendata/form": "./app/javascript/legacy/opendata/form.js",
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
