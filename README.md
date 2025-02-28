# TokenVerse
A decentralized NFT platform for community-driven storytelling built on Stacks.

## Features
- Create story-based NFT collections
- Mint NFTs with story metadata
- Contribute to existing stories
- Vote on story direction
- Trade NFTs between users

## Setup and Installation
1. Clone the repository
2. Install Clarinet (`curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xz`)
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Create a new story collection
(contract-call? .tokenverse create-collection "The Heroes Journey" "A community tale of adventure")

;; Mint a story NFT
(contract-call? .tokenverse mint-story-nft u1 "Chapter 1: The Beginning" "Once upon a time...")

;; Vote on story direction
(contract-call? .tokenverse vote-story-direction u1 u2)

;; Transfer NFT
(contract-call? .tokenverse transfer-nft u1 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

## Dependencies
- Clarity language
- Clarinet for testing/deployment
