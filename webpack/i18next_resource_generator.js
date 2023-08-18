const fs = require("fs");
const merge = require("deepmerge");
const path = require("path");
const yaml = require('js-yaml')
const Config = require("../webpack/config")

const LOCALE_DIR = path.resolve(__dirname, "../config/locales")

function* getFiles(dir) {
  const dirents = fs.readdirSync(dir, { withFileTypes: true })
  for (const dirent of dirents) {
    const res = path.resolve(dir, dirent.name)
    if (dirent.isDirectory()) {
      yield* getFiles(res)
    } else {
      yield res
    }
  }
}

function replaceInterpolation(text) {
  return text.replace(/%{\w+?}/g, (match, _offset, _string) => `{{${match.slice(2, -1)}}}`)
}

function loadLocale(lang) {
  const basename = `${lang}.yml`
  let locale = {}

  for (const filePath of getFiles(LOCALE_DIR)) {
    if (! filePath.endsWith(basename)) {
      continue
    }

    const single = yaml.load(replaceInterpolation(fs.readFileSync(filePath, 'utf8')))
    locale = merge(locale, single)
  }

  return locale[lang]
}

module.exports = {
  generate: function() {
    const locales = {};

    Config.environment.available_locales.forEach((lang) => {
      locales[lang] = { translation: loadLocale(lang) }
    })

    return locales
  }
}
