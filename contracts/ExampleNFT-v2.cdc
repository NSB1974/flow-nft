/* 
*
*  This is an example implementation of a Flow Non-Fungible Token
*  using the V2 standard.
*  It is not part of the official standard but it assumed to be
*  similar to how many NFTs would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its NFTs. It defines a simple NFT with minimal metadata.
*   
*/

import NonFungibleToken from "NonFungibleToken"
import MultipleNFT from "MultipleNFT"
import ViewResolver from "ViewResolver"
import MetadataViews from "MetadataViews"

access(all) contract ExampleNFT: ViewResolver {

    /// Path where the minter should be stored
    /// The standard paths for the collection are stored in the collection resource type
    access(all) let MinterStoragePath: StoragePath

    /// We choose the name NFT here, but this type can have any name now
    /// because the interface does not require it to have a specific name any more
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {

        access(all) view fun getID(): UInt64 {
            return self.uuid
        }

        /// From the Display metadata view
        access(all) let name: String
        access(all) let description: String
        access(all) let thumbnail: String

        /// For the Royalties metadata view
        access(self) let royalties: [MetadataViews.Royalty]

        /// Generic dictionary of traits the NFT has
        access(self) let metadata: {String: AnyStruct}
    
        init(
            name: String,
            description: String,
            thumbnail: String,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
        ) {
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            self.metadata = metadata
        }
    
        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "Example NFT Edition", number: self.getID(), max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.getID()
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://example-nft.onflow.org/".concat(self.getID().toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return ExampleNFT.getCollectionData(nftType: Type<@ExampleNFT.NFT>())
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return ExampleNFT.getCollectionDisplay(nftType: Type<@ExampleNFT.NFT>())
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["mintedTime", "foo"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    // foo is a trait with its own rarity
                    let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
                    let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
                    traitsView.addTrait(fooTrait)
                    
                    return traitsView

            }
            return nil
        }
    }

    access(all) resource Collection: NonFungibleToken.Collection {
        /// dictionary of NFT conforming tokens
        /// NFT is a resource type with an `UInt64` ID field
        access(contract) var ownedNFTs: @{UInt64: ExampleNFT.NFT}

        access(self) var storagePath: StoragePath
        access(self) var publicPath: PublicPath

        /// Return the default storage path for the collection
        access(all) view fun getDefaultStoragePath(): StoragePath? {
            return self.storagePath
        }

        /// Return the default public path for the collection
        access(all) view fun getDefaultPublicPath(): PublicPath? {
            return self.publicPath
        }

        init () {
            self.ownedNFTs <- {}
            let identifier = "cadenceExampleNFTCollection"
            self.storagePath = StoragePath(identifier: identifier)!
            self.publicPath = PublicPath(identifier: identifier)!
        }

        /// getSupportedNFTTypes returns a list of NFT types that this receiver accepts
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[Type<@ExampleNFT.NFT>()] = true
            return supportedTypes
        }

        /// Returns whether or not the given type is accepted by the collection
        /// A collection that can accept any type should just return true by default
        access(all) view fun isSupportedNFTType(type: Type): Bool {
           if type == Type<@ExampleNFT.NFT>() {
            return true
           } else {
            return false
           }
        }

        /// withdraw removes an NFT from the collection and moves it to the caller
        access(NonFungibleToken.Withdrawable) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Could not withdraw an NFT with the provided ID from the collection")

            return <-token
        }

        /// deposit takes a NFT and adds it to the collections dictionary
        /// and adds the ID to the id array
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let token <- token as! @ExampleNFT.NFT

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[token.getID()] <- token

            destroy oldToken
        }

        /// getIDs returns an array of the IDs that are in the collection
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Gets the amount of NFTs stored in the collection
        access(all) view fun getLength(): Int {
            return self.ownedNFTs.keys.length
        }

        /// borrowNFT gets a reference to an NFT in the collection
        /// so that the caller can read its metadata and call its methods
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT} {
            let nftRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
                ?? panic("Could not borrow a reference to an NFT with the specified ID")

            return nftRef
        }

        access(all) view fun borrowNFTSafe(id: UInt64): &{NonFungibleToken.NFT}? {
            return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
        }

        /// Borrow the view resolver for the specified NFT ID
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &ExampleNFT.NFT? {
                return nft as &{ViewResolver.Resolver}
            }
            return nil
        }

        /// public function that anyone can call to create a new empty collection
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create ExampleNFT.Collection()
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// public function that anyone can call to create a new empty collection
    /// Since multiple collection types can be defined in a contract,
    /// The caller needs to specify which one they want to create
    access(all) fun createEmptyCollection(): @ExampleNFT.Collection {
        return <- create Collection()
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    access(all) view fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    access(all) fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return ExampleNFT.getCollectionData(nftType: Type<@ExampleNFT.NFT>())
            case Type<MetadataViews.NFTCollectionDisplay>():
                return ExampleNFT.getCollectionDisplay(nftType: Type<@ExampleNFT.NFT>())
        }
        return nil
    }

    /// resolve a type to its CollectionData so you know where to store it
    /// Returns `nil` if no collection type exists for the specified NFT type
    access(all) view fun getCollectionData(nftType: Type): MetadataViews.NFTCollectionData? {
        switch nftType {
            case Type<@ExampleNFT.NFT>():
                let collectionRef = self.account.storage.borrow<&ExampleNFT.Collection>(
                        from: /storage/cadenceExampleNFTCollection
                    ) ?? panic("Could not borrow a reference to the stored collection")
                let collectionData = MetadataViews.NFTCollectionData(
                    storagePath: collectionRef.getDefaultStoragePath()!,
                    publicPath: collectionRef.getDefaultPublicPath()!,
                    providerPath: /private/cadenceExampleNFTCollection,
                    publicCollection: Type<&ExampleNFT.Collection>(),
                    publicLinkedType: Type<&ExampleNFT.Collection>(),
                    providerLinkedType: Type<auth(NonFungibleToken.Withdrawable) &ExampleNFT.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <-collectionRef.createEmptyCollection()
                    })
                )
                return collectionData
            default:
                return nil
        }
    }

    /// Returns the CollectionDisplay view for the NFT type that is specified 
    access(all) view fun getCollectionDisplay(nftType: Type): MetadataViews.NFTCollectionDisplay? {
        switch nftType {
            case Type<@ExampleNFT.NFT>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "The Example Collection",
                    description: "This collection is used as an example to help you develop your next Flow NFT.",
                    externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
                    }
                )
            default:
                return nil
        }
    }

    /// Resource that an admin or something similar would own to be
    /// able to mint new NFTs
    ///
    access(all) resource NFTMinter {

        /// mintNFT mints a new NFT with a new ID
        /// and returns it to the calling context
        access(all) fun mintNFT(
            name: String,
            description: String,
            thumbnail: String,
            royalties: [MetadataViews.Royalty]
        ): @ExampleNFT.NFT {

            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp

            // this piece of metadata will be used to show embedding rarity into a trait
            metadata["foo"] = "bar"

            // create a new NFT
            var newNFT <- create NFT(
                name: name,
                description: description,
                thumbnail: thumbnail,
                royalties: royalties,
                metadata: metadata,
            )

            return <-newNFT
        }
    }

    init() {

        // Set the named paths
        self.MinterStoragePath = /storage/cadenceExampleNFTMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        let defaultStoragePath = collection.getDefaultStoragePath()!
        let defaultPublicPath = collection.getDefaultPublicPath()!
        self.account.storage.save(<-collection, to: defaultStoragePath)

        // create a public capability for the collection
        let collectionCap = self.account.capabilities.storage.issue<&ExampleNFT.Collection>(defaultStoragePath)
        self.account.capabilities.publish(collectionCap, at: defaultPublicPath)

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.storage.save(<-minter, to: self.MinterStoragePath)
    }
}
 