const { WalletServer } = require('cardano-wallet-js');
let walletServer = WalletServer.init('http://localhost:8090/v2');

const run = async () => {
    let information = await walletServer.getNetworkInformation();
    console.log(information);

    let parameters = await walletServer.getNetworkParameters();
    console.log(parameters);
}

run();
