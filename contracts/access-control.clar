;; Access Control Contract
;; Governs who can view or verify specific credentials

(define-map access-permissions
{ student-id: (buff 32), verifier: principal }
{
  granted-at: uint,
  expires-at: (optional uint),
  access-type: (string-ascii 20)
}
)

(define-read-only (get-access-permission (student-id (buff 32)) (verifier principal))
(map-get? access-permissions { student-id: student-id, verifier: verifier })
)

(define-public (grant-access (student-id (buff 32)) (verifier principal) (access-type (string-ascii 20)) (duration (optional uint)))
(let
  (
    (expiration (match duration
      dur (some (+ block-height dur))
      none
    ))
  )
  (ok (map-set access-permissions
    { student-id: student-id, verifier: verifier }
    {
      granted-at: block-height,
      expires-at: expiration,
      access-type: access-type
    }
  ))
)
)

(define-public (revoke-access (student-id (buff 32)) (verifier principal))
(ok (map-delete access-permissions { student-id: student-id, verifier: verifier }))
)

(define-read-only (check-access (student-id (buff 32)) (verifier principal) (required-access-type (string-ascii 20)))
(match (get-access-permission student-id verifier)
  permission (and
    (is-eq (get access-type permission) required-access-type)
    (match (get expires-at permission)
      expiry (< block-height expiry)
      true
    )
  )
  false
)
)

(define-read-only (has-any-access (student-id (buff 32)) (verifier principal))
(is-some (get-access-permission student-id verifier))
)

