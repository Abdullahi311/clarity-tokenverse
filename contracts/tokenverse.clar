;; TokenVerse - Community Storytelling NFT Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-authorized (err u103))
(define-constant err-invalid-vote (err u104))
(define-constant err-already-voted (err u105))
(define-constant err-invalid-input (err u106))

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

(define-map user-votes
  { user: principal, nft-id: uint }
  bool
)

(define-data-var next-collection-id uint u1)
(define-data-var next-nft-id uint u1)

;; Private functions
(define-private (is-collection-active (collection-id uint))
  (default-to false (get active (unwrap! (map-get? story-collections collection-id) false)))
)

(define-private (validate-string (str (string-ascii 100)))
  (not (is-eq str ""))
)

;; Public functions
(define-public (create-collection (name (string-ascii 100)) (description (string-ascii 500)))
  (let ((collection-id (var-get next-collection-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (validate-string name) err-invalid-input)
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

(define-public (toggle-collection-status (collection-id uint))
  (let ((collection (unwrap! (map-get? story-collections collection-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set story-collections collection-id
      (merge collection { active: (not (get active collection)) })
    )
    (ok true)
  )
)

(define-public (mint-story-nft (collection-id uint) (title (string-ascii 100)) (content (string-utf8 1000)))
  (let ((nft-id (var-get next-nft-id)))
    (asserts! (is-collection-active collection-id) err-not-found)
    (asserts! (validate-string title) err-invalid-input)
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
  (let 
    (
      (story (unwrap! (map-get? story-nfts nft-id) err-not-found))
      (vote-key { user: tx-sender, nft-id: nft-id })
    )
    (asserts! (< direction u3) err-invalid-vote)
    (asserts! (not (default-to false (map-get? user-votes vote-key))) err-already-voted)
    (map-set story-nfts nft-id
      (merge story { votes: (+ (get votes story) u1) })
    )
    (map-set user-votes vote-key true)
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

(define-read-only (has-voted (user principal) (nft-id uint))
  (default-to false (map-get? user-votes { user: user, nft-id: nft-id }))
)
