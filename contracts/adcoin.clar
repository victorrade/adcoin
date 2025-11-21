(define-trait sip010-ft-trait
  (
    ;; Metadata
    (get-name () (response (string-utf8 32) uint))
    (get-symbol () (response (string-utf8 8) uint))
    (get-decimals () (response uint uint))
    (get-total-supply () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))

    ;; Core token functions
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (mint (uint principal (optional (buff 34))) (response bool uint))
    (burn (uint principal (optional (buff 34))) (response bool uint))
  )
)

;; -----------------------------------------------------------------------------
;; Constants & Errors
;; -----------------------------------------------------------------------------

(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INSUFFICIENT-BALANCE u101)
(define-constant ERR-INSUFFICIENT-SUPPLY u102)

(define-constant TOKEN-NAME "Adcoin")
(define-constant TOKEN-SYMBOL "ADCOIN")
(define-constant TOKEN-DECIMALS u6)
(define-constant TOKEN-URI (some "https://example.com/adcoin/metadata.json"))

;; -----------------------------------------------------------------------------
;; Data
;; -----------------------------------------------------------------------------

;; Contract owner is the deployer
(define-data-var owner principal tx-sender)

(define-data-var total-supply uint u0)

(define-map balances
  { owner: principal }
  { balance: uint })

;; -----------------------------------------------------------------------------
;; Internal helpers
;; -----------------------------------------------------------------------------

(define-read-only (get-owner)
  (var-get owner)
)

(define-private (only-owner)
  (ok (is-eq tx-sender (var-get owner)))
)

(define-private (get-balance-internal (who principal))
  (default-to u0 (get balance (map-get? balances { owner: who })))
)

(define-private (set-balance! (who principal) (amount uint))
  (map-set balances { owner: who } { balance: amount })
)

(define-private (transfer-internal (amount uint) (sender principal) (recipient principal))
  (let (
        (sender-balance (get-balance-internal sender))
        (recipient-balance (get-balance-internal recipient))
       )
    (if (>= sender-balance amount)
        (begin
          (set-balance! sender (- sender-balance amount))
          (set-balance! recipient (+ recipient-balance amount))
          (ok true))
        (err ERR-INSUFFICIENT-BALANCE)))
)

(define-private (mint-internal (amount uint) (recipient principal))
  (let (
        (current-balance (get-balance-internal recipient))
        (current-supply (var-get total-supply))
       )
    (begin
      (set-balance! recipient (+ current-balance amount))
      (var-set total-supply (+ current-supply amount))
      (ok true)))
)

(define-private (burn-internal (amount uint) (sender principal))
  (let (
        (current-balance (get-balance-internal sender))
        (current-supply (var-get total-supply))
       )
    (if (>= current-balance amount)
        (begin
          (set-balance! sender (- current-balance amount))
          (var-set total-supply (- current-supply amount))
          (ok true))
        (err ERR-INSUFFICIENT-BALANCE)))
)

;; -----------------------------------------------------------------------------
;; SIP-010 Read-only functions
;; -----------------------------------------------------------------------------

(define-read-only (get-name)
  (ok TOKEN-NAME)
)

(define-read-only (get-symbol)
  (ok TOKEN-SYMBOL)
)

(define-read-only (get-decimals)
  (ok TOKEN-DECIMALS)
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-read-only (get-balance (who principal))
  (ok (get-balance-internal who))
)

(define-read-only (get-token-uri)
  (ok TOKEN-URI)
)

;; -----------------------------------------------------------------------------
;; SIP-010 Public entrypoints
;; -----------------------------------------------------------------------------

(define-public (transfer (amount uint)
                         (sender principal)
                         (recipient principal)
                         (memo (optional (buff 34))))
  (begin
    (if (is-eq sender tx-sender)
        (transfer-internal amount sender recipient)
        (err ERR-NOT-AUTHORIZED)))
)

(define-public (mint (amount uint)
                     (recipient principal)
                     (memo (optional (buff 34))))
  (begin
    (match (only-owner)
      ok-owner
        (if ok-owner
            (mint-internal amount recipient)
            (err ERR-NOT-AUTHORIZED))
      err-code (err err-code)))
)

(define-public (burn (amount uint)
                     (sender principal)
                     (memo (optional (buff 34))))
  (begin
    (if (is-eq sender tx-sender)
        (burn-internal amount sender)
        (err ERR-NOT-AUTHORIZED)))
)
