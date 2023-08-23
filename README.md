# `RakeoffStatistics()`

This repo contains the smart contract code for the Rakeoff statistics smart contract that tracks some important stats about the Rakeoff dApp.

You can visit the Rakeoff dApp here [app.rakeoff.io](https://app.rakeoff.io/)

## Overview of the tech stack

- [Motoko](https://react.dev/](https://internetcomputer.org/docs/current/motoko/main/motoko?source=nav)) is used for the smart contract programming language.
- The IC SDK: [DFX](https://internetcomputer.org/docs/current/developer-docs/setup/install) is used to make this an ICP project.

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

