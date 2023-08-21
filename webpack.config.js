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
  devtool: RAILS_ENV === "production" ? "source-map" : "eval-source-map",
  entry: {
    application: "./app/javascript/application.js",
    colorbox: "./app/javascript/colorbox.js",
  },
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
    sourceMapFilename: "[name].js.map",
    path: path.resolve(__dirname, "app/assets/builds"),
  },
  plugins: [
    new webpack.DefinePlugin({
      RAILS_ENV: JSON.stringify(RAILS_ENV),
      AVAILABLE_LOCALES: JSON.stringify(Config.environment.available_locales),
      I18NEXT_RESOURCES: JSON.stringify(RAILS_ENV === "production" ? i18nextResourceGen.generate() : {})
    }),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new CleanWebpackPlugin({
      cleanOnceBeforeBuildPatterns: [ "**/*.js", "**/*.css" ]
    }),
    new RemoveEmptyScriptsPlugin(),
    new webpack.SourceMapDevToolPlugin({
      filename: '[name][ext].map'
    }),
    new MiniCssExtractPlugin({
      filename: '[name].css'
    })
  ]
}
