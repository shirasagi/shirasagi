const fs = require('fs')
const merge = require('deepmerge')
const path = require("path")
const yaml = require('js-yaml')

function loadYaml(path) {
  if (! fs.existsSync(path)) {
    return
  }

  return yaml.load(fs.readFileSync(path, 'utf8'))
}

function buildConfig(section) {
  const config1 = loadYaml(path.resolve(__dirname, `../config/${section}.yml`))
  const config2 = loadYaml(path.resolve(__dirname, `../config/defaults/${section}.yml`))

  if (config1 && config2) {
    return Object.freeze(merge(config2, config1))
  } else if (config1) {
    return Object.freeze(config1)
  } else if (config2) {
    return Object.freeze(config2)
  }
}

module.exports = {
  // chorg: buildConfig("chorg"),
  cms: buildConfig("cms"),
  environment: buildConfig("environment"),
  // event: buildConfig("event"),
  // ezine: buildConfig("ezine"),
  // gravatar: buildConfig("gravatar"),
  gws: buildConfig("gws"),
  // ie11: buildConfig("ie11"),
  // job: buildConfig("job"),
  // kana: buildConfig("kana"),
  // ldap: buildConfig("ldap"),
  // lgwan: buildConfig("lgwan"),
  mail: buildConfig("mail"),
  map: buildConfig("map"),
  // michecker: buildConfig("michecker"),
  // opendata: buildConfig("opendata"),
  // proxy: buildConfig("proxy"),
  recommend: buildConfig("recommend"),
  // rss: buildConfig("rss"),
  // service: buildConfig("service"),
  // sns: buildConfig("sns"),
  // ss: buildConfig("ss"),
  // translate: buildConfig("translate"),
  // voice: buildConfig("voice"),
  // webmail: buildConfig("webmail"),
  // workflow: buildConfig("workflow"),
}
