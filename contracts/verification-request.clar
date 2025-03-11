;; Verification Request Contract
;; Manages inquiries about academic credentials

(define-map verification-requests
{ request-id: uint }
{
  verifier: principal,
  credential-id: uint,
  request-date: uint,
  status: (string-ascii 20),
  response-date: (optional uint)
}
)

(define-data-var request-nonce uint u0)

(define-constant contract-owner tx-sender)

(define-read-only (get-verification-request (request-id uint))
(map-get? verification-requests { request-id: request-id })
)

(define-public (create-verification-request (credential-id uint))
(let
  (
    (new-request-id (+ (var-get request-nonce) u1))
  )
  (var-set request-nonce new-request-id)
  (ok (map-set verification-requests
    { request-id: new-request-id }
    {
      verifier: tx-sender,
      credential-id: credential-id,
      request-date: block-height,
      status: "pending",
      response-date: none
    }
  ))
)
)

(define-public (respond-to-verification-request (request-id uint) (approved bool))
(let
  (
    (request (unwrap! (get-verification-request request-id) (err u404)))
  )
  (asserts! (is-eq tx-sender contract-owner) (err u403))
  (ok (map-set verification-requests
    { request-id: request-id }
    (merge request
      {
        status: (if approved "approved" "rejected"),
        response-date: (some block-height)
      }
    )
  ))
)
)

(define-read-only (get-verification-status (request-id uint))
(match (get-verification-request request-id)
  request (get status request)
  "not-found"
)
)

