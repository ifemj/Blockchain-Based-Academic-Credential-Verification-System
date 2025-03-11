;; Credential Issuance Contract
;; Records academic achievements and qualifications

(define-map credentials
{ credential-id: uint }
{
  student-id: (buff 32),
  institution: principal,
  credential-type: (string-ascii 50),
  credential-name: (string-ascii 100),
  issue-date: uint,
  expiration-date: (optional uint),
  metadata: (string-ascii 256),
  revoked: bool
}
)

(define-data-var credential-nonce uint u0)

(define-constant contract-owner tx-sender)

(define-read-only (get-credential (credential-id uint))
(map-get? credentials { credential-id: credential-id })
)

(define-public (issue-credential
  (student-id (buff 32))
  (credential-type (string-ascii 50))
  (credential-name (string-ascii 100))
  (expiration-date (optional uint))
  (metadata (string-ascii 256))
)
(let
  (
    (new-credential-id (+ (var-get credential-nonce) u1))
  )
  (asserts! (or (is-eq tx-sender contract-owner) (is-approved-institution tx-sender)) (err u403))
  (var-set credential-nonce new-credential-id)
  (ok (map-set credentials
    { credential-id: new-credential-id }
    {
      student-id: student-id,
      institution: tx-sender,
      credential-type: credential-type,
      credential-name: credential-name,
      issue-date: block-height,
      expiration-date: expiration-date,
      metadata: metadata,
      revoked: false
    }
  ))
)
)

(define-public (revoke-credential (credential-id uint))
(let
  (
    (credential (unwrap! (get-credential credential-id) (err u404)))
  )
  (asserts! (is-eq (get institution credential) tx-sender) (err u403))
  (ok (map-set credentials
    { credential-id: credential-id }
    (merge credential { revoked: true })
  ))
)
)

(define-public (update-credential-metadata (credential-id uint) (new-metadata (string-ascii 256)))
(let
  (
    (credential (unwrap! (get-credential credential-id) (err u404)))
  )
  (asserts! (is-eq (get institution credential) tx-sender) (err u403))
  (ok (map-set credentials
    { credential-id: credential-id }
    (merge credential { metadata: new-metadata })
  ))
)
)

(define-read-only (is-credential-valid (credential-id uint))
(match (get-credential credential-id)
  credential (and
    (not (get revoked credential))
    (match (get expiration-date credential)
      expiry (< block-height expiry)
      true
    )
  )
  false
)
)

(define-map approved-institutions
{ institution: principal }
{ approved: bool }
)

(define-public (approve-institution (institution principal))
(begin
  (asserts! (is-eq tx-sender contract-owner) (err u403))
  (ok (map-set approved-institutions
    { institution: institution }
    { approved: true }
  ))
)
)

(define-public (revoke-institution-approval (institution principal))
(begin
  (asserts! (is-eq tx-sender contract-owner) (err u403))
  (ok (map-set approved-institutions
    { institution: institution }
    { approved: false }
  ))
)
)

(define-read-only (is-approved-institution (institution principal))
(default-to false (get approved (map-get? approved-institutions { institution: institution })))
)

