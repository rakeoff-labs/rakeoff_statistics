# `RakeoffStatistics()`

This repo contains the smart contract code for the Rakeoff statistics smart contract that tracks some important stats about the Rakeoff dApp.

You can visit the Rakeoff dApp here [app.rakeoff.io](https://app.rakeoff.io/)

## Overview of the tech stack

- [Motoko](https://react.dev/](https://internetcomputer.org/docs/current/motoko/main/motoko?source=nav)) is used for the smart contract programming language.
- The IC SDK: [DFX](https://internetcomputer.org/docs/current/developer-docs/setup/install) is used to make this an ICP project.

### How does it work?

The smart contract maintains a record of users and their staked ICP amounts in stable memory. It also aggregates data from various components of Rakeoff, including the achievements and RakeoffKernel smart contracts, and compiles this data into comprehensive statistics. Helper functions facilitate the retrieval of this information. All these details are then formatted as JSON and provided through the API at: https://jgvzt-eiaaa-aaaak-ae5kq-cai.icp0.io/v1/rakeoff-stats. The API is refreshed every 24 hours.

To build this, we utilized [Mops](https://mops.one/) and the [Motoko Server package](https://github.com/krpeacock/server).

### If you want to clone onto your local machine

Make sure you have `git` and `dfx` installed
```bash
# clone the repo
git clone #<get the repo ssh>

# change directory
cd rakeoff_statistics

# set up the dfx local server
dfx start --background --clean

# deploy the canisters locally
dfx deploy

# ....
# when you are done make sure to stop the local server:
dfx stop
```

## License

The `RakeoffStatistics()()` smart contract code is distributed under the terms of the Apache 2.0 License.

See LICENSE for details.

