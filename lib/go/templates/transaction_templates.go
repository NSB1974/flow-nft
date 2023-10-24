package templates

import (
	"github.com/onflow/flow-go-sdk"

	_ "github.com/kevinburke/go-bindata"

	"github.com/onflow/flow-nft/lib/go/templates/internal/assets"
)

const (
	filenameUpgradeNFT                   = "transactions/test/upgrade_nft_contract.cdc"
	filenameSetupAccount                 = "transactions/setup_account.cdc"
	filenameMintNFT                      = "transactions/mint_nft.cdc"
	filenameTransferNFT                  = "transactions/transfer_nft.cdc"
	filenameDestroyNFT                   = "transactions/destroy_nft.cdc"
	filenameSetupRoyalty                 = "transactions/setup_account_to_receive_royalty.cdc"
	filenameSetupAccountFromNftReference = "transactions/setup_account_from_nft_reference.cdc"
)

func GenerateUpgradeNFTContract() []byte {
	code := assets.MustAssetString(filenameUpgradeNFT)
	return replaceAddresses(code, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress, flow.EmptyAddress)
}

// GenerateSetupAccountScript returns a script that instantiates a new
// NFT collection instance, saves the collection in storage, then stores a
// reference to the collection.
func GenerateSetupAccountScript(nftAddress, exampleNFTAddress, metadataViewsAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameSetupAccount)
	return replaceAddresses(code, nftAddress, exampleNFTAddress, metadataViewsAddress, flow.EmptyAddress, flow.EmptyAddress)
}

// GenerateMintNFTScript returns script that uses the admin resource
// to mint a new NFT and deposit it into a user's collection.
func GenerateMintNFTScript(nftAddress, exampleNFTAddress, metadataViewsAddress, ftAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameMintNFT)
	return replaceAddresses(code, nftAddress, exampleNFTAddress, metadataViewsAddress, ftAddress, flow.EmptyAddress)
}

// GenerateTransferNFTScript returns a script that withdraws an NFT token
// from a collection and deposits it into another collection.
func GenerateTransferNFTScript(nftAddress, exampleNFTAddress, metadataAddress, viewResolverAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameTransferNFT)
	return replaceAddresses(code, nftAddress, exampleNFTAddress, metadataAddress, flow.EmptyAddress, viewResolverAddress)
}

// GenerateDestroyNFTScript creates a script that withdraws an NFT token
// from a collection and destroys it.
func GenerateDestroyNFTScript(nftAddress, exampleNFTAddress, metadataAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameDestroyNFT)
	return replaceAddresses(code, nftAddress, exampleNFTAddress, metadataAddress, flow.EmptyAddress, flow.EmptyAddress)
}

// GenerateSetupAccountToReceiveRoyaltyScript returns a script that
// links a new royalty receiver interface
func GenerateSetupAccountToReceiveRoyaltyScript(metadataViewsAddress, ftAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameSetupRoyalty)
	return replaceAddresses(code, flow.EmptyAddress, flow.EmptyAddress, metadataViewsAddress, ftAddress, flow.EmptyAddress)
}

// GenerateSetupAccountFromNftReferenceScript returns a script that instantiates a new
// NFT collection instance, saves the collection in storage, then stores a
// reference to the collection.
func GenerateSetupAccountFromNftReferenceScript(nftAddress, metadataViewsAddress flow.Address) []byte {
	code := assets.MustAssetString(filenameSetupAccountFromNftReference)
	return replaceAddresses(code, nftAddress, flow.EmptyAddress, metadataViewsAddress, flow.EmptyAddress, flow.EmptyAddress)
}
