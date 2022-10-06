const UpgradableCheckDotERC721InsuranceToken = artifacts.require('UpgradableCheckDotERC721InsuranceToken');
const CheckDotERC721InsuranceToken = artifacts.require('CheckDotERC721InsuranceToken');

module.exports = async function (deployer, network, accounts) {
    if (network == "development") return;
    const proxy = await UpgradableCheckDotERC721InsuranceToken.deployed();
    const protocol = await CheckDotERC721InsuranceToken.at(proxy.address);

    console.log("Proxy", proxy.address);

    console.log(await protocol.teamApproveClaim(0, 0, true, `Test of expertise:\nhttps://docs.google.com/document/d/1DtHPDNTElqMzJOVlB8VjKWoiA9jblnPJXEvD9pXtQEM/edit?usp=sharing`));
};