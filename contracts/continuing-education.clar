;; Continuing Education Contract
;; Tracks ongoing professional development and certifications

(define-map continuing-education
{ record-id: uint }
{
  student-id: (buff 32),
  provider: principal,
  course-name: (string-ascii 100),
  course-type: (string-ascii 50),
  credits: uint,
  completion-date: uint,
  expiration-date: (optional uint),
  verified: bool
}
)

(define-data-var record-nonce uint u0)

(define-constant contract-owner tx-sender)

(define-read-only (get-education-record (record-id uint))
(map-get? continuing-education { record-id: record-id })
)

(define-public (add-education-record
  (student-id (buff 32))
  (course-name (string-ascii 100))
  (course-type (string-ascii 50))
  (credits uint)
  (expiration-date (optional uint))
)
(let
  (
    (new-record-id (+ (var-get record-nonce) u1))
  )
  (var-set record-nonce new-record-id)
  (ok (map-set continuing-education
    { record-id: new-record-id }
    {
      student-id: student-id,
      provider: tx-sender,
      course-name: course-name,
      course-type: course-type,
      credits: credits,
      completion-date: block-height,
      expiration-date: expiration-date,
      verified: false
    }
  ))
)
)

(define-public (verify-education-record (record-id uint))
(let
  (
    (record (unwrap! (get-education-record record-id) (err u404)))
  )
  (asserts! (or (is-eq tx-sender contract-owner) (is-approved-provider tx-sender)) (err u403))
  (ok (map-set continuing-education
    { record-id: record-id }
    (merge record { verified: true })
  ))
)
)

(define-public (update-education-record (record-id uint) (credits uint) (expiration-date (optional uint)))
(let
  (
    (record (unwrap! (get-education-record record-id) (err u404)))
  )
  (asserts! (is-eq (get provider record) tx-sender) (err u403))
  (ok (map-set continuing-education
    { record-id: record-id }
    (merge record
      {
        credits: credits,
        expiration-date: expiration-date
      }
    )
  ))
)
)

(define-read-only (is-education-record-valid (record-id uint))
(match (get-education-record record-id)
  record (and
    (get verified record)
    (match (get expiration-date record)
      expiry (< block-height expiry)
      true
    )
  )
  false
)
)

(define-map approved-providers
{ provider: principal }
{ approved: bool }
)

(define-public (approve-provider (provider principal))
(begin
  (asserts! (is-eq tx-sender contract-owner) (err u403))
  (ok (map-set approved-providers
    { provider: provider }
    { approved: true }
  ))
)
)

(define-public (revoke-provider-approval (provider principal))
(begin
  (asserts! (is-eq tx-sender contract-owner) (err u403))
  (ok (map-set approved-providers
    { provider: provider }
    { approved: false }
  ))
)
)

(define-read-only (is-approved-provider (provider principal))
(default-to false (get approved (map-get? approved-providers { provider: provider })))
)

;; Instead of trying to filter and return all records, we'll provide a function
;; to check if a specific record belongs to a student
(define-read-only (is-student-record (record-id uint) (student-id (buff 32)))
(match (get-education-record record-id)
  record (is-eq (get student-id record) student-id)
  false
)
)

