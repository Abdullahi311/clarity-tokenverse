;; TokenVerse - Community Storytelling NFT Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-authorized (err u103))

;; Define NFT token
(define-non-fungible-token story-nft uint)

;; Data structures
(define-map story-collections
  uint 
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    active: bool
  }
)

(define-map story-nfts
  uint
  {
    title: (string-ascii 100),
    content: (string-utf8 1000),
    collection-id: uint,
    creator: principal,
    votes: uint
  }
)

(define-data-var next-collection-id uint u1)
(define-data-var next-nft-id uint u1)

;; Public functions
(define-public (create-collection (name (string-ascii 100)) (description (string-ascii 500)))
  (let ((collection-id (var-get next-collection-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-insert story-collections collection-id
      {
        name: name,
        description: description,
        creator: tx-sender,
        active: true
      }
    )
    (var-set next-collection-id (+ collection-id u1))
    (ok collection-id)
  )
)

(define-public (mint-story-nft (collection-id uint) (title (string-ascii 100)) (content (string-utf8 1000)))
  (let ((nft-id (var-get next-nft-id)))
    (asserts! (is-collection-active collection-id) err-not-found)
    (try! (nft-mint? story-nft nft-id tx-sender))
    (map-insert story-nfts nft-id
      {
        title: title,
        content: content,
        collection-id: collection-id,
        creator: tx-sender,
        votes: u0
      }
    )
    (var-set next-nft-id (+ nft-id u1))
    (ok nft-id)
  )
)

(define-public (vote-story-direction (nft-id uint) (direction uint))
  (let ((story (unwrap! (map-get? story-nfts nft-id) err-not-found)))
    (map-set story-nfts nft-id
      (merge story { votes: (+ (get votes story) u1) })
    )
    (ok true)
  )
)

(define-public (transfer-nft (nft-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-authorized)
    (nft-transfer? story-nft nft-id sender recipient)
  )
)

;; Read-only functions
(define-read-only (get-collection (collection-id uint))
  (ok (map-get? story-collections collection-id))
)

(define-read-only (get-story-nft (nft-id uint))
  (ok (map-get? story-nfts nft-id))
)

;; Private functions
(define-private (is-collection-active (collection-id uint))
  (default-to false (get active (unwrap! (map-get? story-collections collection-id) false)))
)
