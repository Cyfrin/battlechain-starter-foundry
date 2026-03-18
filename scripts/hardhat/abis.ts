// ABI fragments for BattleChain protocol contracts.
// Addresses are from BCConfig.sol (chain ID 627 = testnet).

export const BC = {
  DEPLOYER:         "0x8f57054CBa2021bEE15631067dd7B7E0B43F17Dc",
  AGREEMENT_FACTORY:"0x0EbBEeB3aBeF51801a53Fdd1fb263Ac0f2E3Ed36",
  REGISTRY:         "0xCb2A561395118895e2572A04C2D8AB8eCA8d7E5D",
  ATTACK_REGISTRY:  "0x9E62988ccA776ff6613Fa68D34c9AB5431Ce57e1",
  CAIP2_CHAIN_ID:   "eip155:627",
  SAFE_HARBOR_URI:  "ipfs://bafkreifgln3ir67woluatpwn3b65gjkrbmoq6jgzzotm3anas3vvq4yp4m",
} as const;

export const IBCDeployerABI = [
  "function deployCreate(bytes initCode) payable returns (address newContract)",
  "function deployCreate2(bytes32 salt, bytes initCode) payable returns (address newContract)",
] as const;

export const IAgreementFactoryABI = [
  {
    name: "create",
    type: "function",
    inputs: [
      {
        name: "details",
        type: "tuple",
        components: [
          { name: "protocolName", type: "string" },
          {
            name: "contactDetails",
            type: "tuple[]",
            components: [
              { name: "name", type: "string" },
              { name: "contact", type: "string" },
            ],
          },
          {
            name: "chains",
            type: "tuple[]",
            components: [
              { name: "assetRecoveryAddress", type: "string" },
              {
                name: "accounts",
                type: "tuple[]",
                components: [
                  { name: "accountAddress", type: "string" },
                  { name: "childContractScope", type: "uint8" },
                ],
              },
              { name: "caip2ChainId", type: "string" },
            ],
          },
          {
            name: "bountyTerms",
            type: "tuple",
            components: [
              { name: "bountyPercentage", type: "uint256" },
              { name: "bountyCapUsd", type: "uint256" },
              { name: "retainable", type: "bool" },
              { name: "identity", type: "uint8" },
              { name: "diligenceRequirements", type: "string" },
              { name: "aggregateBountyCapUsd", type: "uint256" },
            ],
          },
          { name: "agreementURI", type: "string" },
        ],
      },
      { name: "owner", type: "address" },
      { name: "salt", type: "bytes32" },
    ],
    outputs: [{ name: "agreementAddress", type: "address" }],
  },
] as const;

export const IAgreementABI = [
  "function extendCommitmentWindow(uint256 newCantChangeUntil) external",
] as const;

export const IBCSafeHarborRegistryABI = [
  "function adoptSafeHarbor(address agreementAddress) external",
] as const;

export const IAttackRegistryABI = [
  "function requestUnderAttack(address agreementAddress) external",
] as const;
