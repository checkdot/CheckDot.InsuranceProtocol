const UpgradableCheckDotPoolFactory = artifacts.require('UpgradableCheckDotPoolFactory');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const CDTGouvernanceTokenAddress = "0x0cbd6fadcf8096cc9a43d90b45f65826102e3ece";
    await deployer.deploy(UpgradableCheckDotPoolFactory, CDTGouvernanceTokenAddress);
};