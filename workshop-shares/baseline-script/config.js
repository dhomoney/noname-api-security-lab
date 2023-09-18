export default {
  crapi: 'CRAPI_HOST',
  mailhog: 'MAILHOG_HOST',
  vinRegex: /\b[(A-Z|0-9)]{17}\b/gm,
  pinRegex: />(\d{4})<\/font>/,
  usersToSimulate: parseInt(process.env.USERS_TO_SIMULATE ?? 100),
  batchSize: 10,
}
