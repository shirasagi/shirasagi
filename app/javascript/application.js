import Initializer from "./ss/initializer"

Initializer.load(require.context("./initializers", true, /\.js$/i))
Initializer.ready(() => console.log("application.js is ready"))
