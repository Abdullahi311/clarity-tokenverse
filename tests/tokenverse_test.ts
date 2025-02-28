import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test collection creation - owner only",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test creation as owner
    let block = chain.mineBlock([
      Tx.contractCall('tokenverse', 'create-collection', 
        [types.ascii("Test Collection"), types.ascii("Test Description")],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Test creation as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall('tokenverse', 'create-collection',
        [types.ascii("Test Collection 2"), types.ascii("Test Description 2")],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test NFT minting and story creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create collection first
    let block = chain.mineBlock([
      Tx.contractCall('tokenverse', 'create-collection',
        [types.ascii("Test Collection"), types.ascii("Test Description")],
        deployer.address
      )
    ]);
    
    // Test NFT minting
    block = chain.mineBlock([
      Tx.contractCall('tokenverse', 'mint-story-nft',
        [
          types.uint(1),
          types.ascii("Test Story"),
          types.utf8("Story content")
        ],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Verify NFT data
    const response = chain.callReadOnlyFn(
      'tokenverse',
      'get-story-nft',
      [types.uint(1)],
      deployer.address
    );
    response.result.expectOk();
  }
});

Clarinet.test({
  name: "Test story voting and NFT transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Setup: Create collection and mint NFT
    let block = chain.mineBlock([
      Tx.contractCall('tokenverse', 'create-collection',
        [types.ascii("Test Collection"), types.ascii("Test Description")],
        deployer.address
      ),
      Tx.contractCall('tokenverse', 'mint-story-nft',
        [
          types.uint(1),
          types.ascii("Test Story"),
          types.utf8("Story content")
        ],
        wallet1.address
      )
    ]);
    
    // Test voting
    block = chain.mineBlock([
      Tx.contractCall('tokenverse', 'vote-story-direction',
        [types.uint(1), types.uint(1)],
        wallet2.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test NFT transfer
    block = chain.mineBlock([
      Tx.contractCall('tokenverse', 'transfer-nft',
        [
          types.uint(1),
          types.principal(wallet1.address),
          types.principal(wallet2.address)
        ],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
