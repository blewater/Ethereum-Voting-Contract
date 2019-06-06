// See <http://truffleframework.com/docs/advanced/configuration>
// to customize your Truffle configuration!

/**
 * Configuration below to attach truffle develop to live ganache instance.
 */
module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*",
            gas: 99999999,
            gasPrice: 10000000000,
        }
    }
}