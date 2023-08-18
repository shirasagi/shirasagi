export default class Initializer {
  static #initialized = false
  static #initializers = []
  static #lazy

  static register(constructor) {
    Initializer.#initializers.push(constructor)
  }

  static load(context) {
    context.keys().forEach(key => {
      const module = context(key)
      const constructor = module.default
      if (typeof constructor == "function") {
        Initializer.register(constructor)
      } else {
        console.info(`${key}: there isn't constructor`)
      }
    })
  }

  static initialize() {
    if (Initializer.#initialized) {
      return Promise.resolve()
    }
    if (Initializer.#lazy) {
      return Initializer.#lazy
    }

    const instances = []
    Initializer.#initializers.forEach(constructor => {
      instances.push(new constructor())
    })

    const promises = []
    instances.forEach(instance => {
      promises.push(instance.initialize())
    })

    Initializer.#lazy = new Promise((resolve, reject) => {
      Promise.all(promises)
        .then(() => {
          promises.length = 0
          instances.forEach(instance => {
            promises.push(instance.afterInitialize())
          })
          return Promise.all(promises)
        })
        .then(() => {
          Initializer.#initialized = true
          resolve()
        })
        .catch(err => reject(err))
    })

    return Initializer.#lazy
  }

  static ready(handler) {
    Initializer.initialize().then(handler)
  }

  initialize() {
    return Promise.resolve()
  }

  afterInitialize() {
    return Promise.resolve()
  }
}
