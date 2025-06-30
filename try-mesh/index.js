const { HydraProvider } = require('@meshsdk/hydra');
const { MeshWallet, MeshTxBuilder } = require('@meshsdk/core');

const provider = new HydraProvider({ url: 'http://localhost:4001' });

async function connect() {
  provider.onMessage((message) => {
    console.log("HydraProvider received message", message);

    if (message.tag === "Greetings") {
      console.log("message.snapshotUtxo", message.snapshotUtxo);
    }
  });

  await provider.connect()

  console.log("HydraProvider connected");

  // try fetching UTxOs for a specific address
  provider.fetchAddressUTxOs('addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z') // Alice-fund
    .then((utxos) => {
      console.log('UTxOs fetched:', utxos);
      console.log('UTxO amount:', utxos[0].output.amount);
    })
    .catch((error) => {
      console.error('Error fetching UTxOs:', error);
    });


  // try submitting a transaction to transfer funds from Alice-fund to Bob-fund within Hydra
  const walletA = {
    addr: "addr_test1vp5cxztpc6hep9ds7fjgmle3l225tk8ske3rmwr9adu0m6qchmx5z", // Alice-fund
    key: "58205f9b911a636479ed83ba601ccfcba0ab9a558269dc19fdea910d27e5cdbb5fc8", // Alice-fund skey
  };

  const wallet = new MeshWallet({
    networkId: 0,
    key: {
      type: "cli",
      payment: walletA.key,
    },
    fetcher: provider,
    submitter: provider,
  });

  const pp = await provider.fetchProtocolParameters();
  const utxos = await wallet.getUtxos("enterprise");
  const changeAddress = walletA.addr;

  const txBuilder = new MeshTxBuilder({
    fetcher: provider,
    params: pp,
    verbose: true,
  });

  const unsignedTx = await txBuilder
    .txOut(
      "addr_test1vp0yug22dtwaxdcjdvaxr74dthlpunc57cm639578gz7algset3fh", // Bob-fund
      [{ unit: "lovelace", quantity: "3000000" }],
    )
    .changeAddress(changeAddress)
    .selectUtxosFrom(utxos)
    .complete();

  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  console.log("txHash", txHash);

}
connect().catch((error) => {
  console.error('Error occured:', error);
});
