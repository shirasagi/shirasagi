const path = require("path")
const webpack = require("webpack")
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const RemoveEmptyScriptsPlugin = require('webpack-remove-empty-scripts')
const { CleanWebpackPlugin } = require('clean-webpack-plugin')
const Config = require("./webpack/config")
const i18nextResourceGen = require("./webpack/i18next_resource_generator")

module.exports = {
  mode: Config.environment.RAILS_ENV === "production" ? "production" : "development",
  devtool: "source-map",
  entry: {
    application: "./app/javascript/application.js",
    "application.css": "./app/javascript/application.scss"
  },
  module: {
    rules: [
      {
        test: /\.(sa|sc|c)ss$/i,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          'postcss-loader',
          'sass-loader'
        ]
      }
    ]
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[name].js.map",
    path: path.resolve(__dirname, "public/assets/builds"),
  },
  plugins: [
    new webpack.DefinePlugin({
      RAILS_ENV: JSON.stringify(Config.environment.RAILS_ENV),
      I18NEXT_RESOURCES: JSON.stringify(Config.environment.RAILS_ENV === "production" ? i18nextResourceGen.generate() : {})
    }),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new CleanWebpackPlugin({
      cleanOnceBeforeBuildPatterns: [ "**/*.js", "**/*.css" ]
    }),
    new RemoveEmptyScriptsPlugin(),
    new MiniCssExtractPlugin({
      filename: '[name]'
    })
  ]
}
