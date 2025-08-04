;; Manufacturing Workflow Incentives Smart Contract
;; Implements a tokenized incentive system for manufacturing employees
;; Tracks quality and delivery targets with automatic STX bonus distribution

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-EMPLOYEE-EXISTS (err u101))
(define-constant ERR-EMPLOYEE-NOT-FOUND (err u102))
(define-constant ERR-INVALID-TARGETS (err u103))
(define-constant ERR-INVALID-PERFORMANCE (err u104))
(define-constant ERR-NO-REWARDS-AVAILABLE (err u105))
(define-constant ERR-REWARD-ALREADY-CLAIMED (err u106))
(define-constant ERR-INSUFFICIENT-CONTRACT-BALANCE (err u107))
(define-constant ERR-INVALID-PERIOD (err u108))
(define-constant ERR-TARGETS-NOT-SET (err u109))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant BLOCKS-PER-PERIOD u2016) ;; Approximately 2 weeks
(define-constant MIN-QUALITY-SCORE u70)
(define-constant MIN-DELIVERY-SCORE u80)
(define-constant BASE-BONUS-AMOUNT u1000000) ;; 1 STX in microSTX
(define-constant QUALITY-WEIGHT u60)
(define-constant DELIVERY-WEIGHT u40)

;; Data structures
(define-map employees
  { employee: principal }
  {
    name: (string-ascii 50),
    department: (string-ascii 30),
    registration-block: uint,
    active: bool,
    total-rewards-earned: uint
  }
)

(define-map targets
  { employee: principal, period: uint }
  {
    quality-target: uint,
    delivery-target: uint,
    bonus-multiplier: uint,
    set-at-block: uint
  }
)

(define-map performance
  { employee: principal, period: uint }
  {
    quality-score: uint,
    delivery-score: uint,
    units-produced: uint,
    defects: uint,
    on-time-deliveries: uint,
    total-deliveries: uint,
    recorded-at-block: uint
  }
)

(define-map rewards
  { employee: principal, period: uint }
  {
    bonus-amount: uint,
    quality-bonus: uint,
    delivery-bonus: uint,
    performance-multiplier: uint,
    claimed: bool,
    claim-block: uint
  }
)

;; Administrative functions
(define-public (register-employee (employee principal) (name (string-ascii 50)) (department (string-ascii 30)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? employees { employee: employee })) ERR-EMPLOYEE-EXISTS)
    (map-set employees
      { employee: employee }
      {
        name: name,
        department: department,
        registration-block: stacks-block-height,
        active: true,
        total-rewards-earned: u0
      }
    )
    (ok true)
  )
)

(define-public (set-employee-targets 
  (employee principal) 
  (period uint) 
  (quality-target uint) 
  (delivery-target uint) 
  (bonus-multiplier uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? employees { employee: employee })) ERR-EMPLOYEE-NOT-FOUND)
    (asserts! (and (>= quality-target u0) (<= quality-target u100)) ERR-INVALID-TARGETS)
    (asserts! (and (>= delivery-target u0) (<= delivery-target u100)) ERR-INVALID-TARGETS)
    (asserts! (and (>= bonus-multiplier u50) (<= bonus-multiplier u300)) ERR-INVALID-TARGETS)
    (map-set targets
      { employee: employee, period: period }
      {
        quality-target: quality-target,
        delivery-target: delivery-target,
        bonus-multiplier: bonus-multiplier,
        set-at-block: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-public (record-performance
  (employee principal)
  (period uint)
  (quality-score uint)
  (delivery-score uint)
  (units-produced uint)
  (defects uint)
  (on-time-deliveries uint)
  (total-deliveries uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? employees { employee: employee })) ERR-EMPLOYEE-NOT-FOUND)
    (asserts! (is-some (map-get? targets { employee: employee, period: period })) ERR-TARGETS-NOT-SET)
    (asserts! (and (>= quality-score u0) (<= quality-score u100)) ERR-INVALID-PERFORMANCE)
    (asserts! (and (>= delivery-score u0) (<= delivery-score u100)) ERR-INVALID-PERFORMANCE)
    (asserts! (<= defects units-produced) ERR-INVALID-PERFORMANCE)
    (asserts! (<= on-time-deliveries total-deliveries) ERR-INVALID-PERFORMANCE)
    
    (map-set performance
      { employee: employee, period: period }
      {
        quality-score: quality-score,
        delivery-score: delivery-score,
        units-produced: units-produced,
        defects: defects,
        on-time-deliveries: on-time-deliveries,
        total-deliveries: total-deliveries,
        recorded-at-block: stacks-block-height
      }
    )
    
    ;; Auto-calculate and set rewards if targets are met
    (let ((calculated-rewards (calculate-bonus employee period)))
      (match calculated-rewards
        success (begin
          (map-set rewards
            { employee: employee, period: period }
            {
              bonus-amount: (get bonus-amount success),
              quality-bonus: (get quality-bonus success),
              delivery-bonus: (get delivery-bonus success),
              performance-multiplier: (get performance-multiplier success),
              claimed: false,
              claim-block: u0
            }
          )
          (ok true)
        )
        error (ok true) ;; Continue even if bonus calculation fails
      )
    )
  )
)

(define-public (claim-rewards (employee principal) (period uint))
  (let (
    (employee-data (unwrap! (map-get? employees { employee: employee }) ERR-EMPLOYEE-NOT-FOUND))
    (reward-data (unwrap! (map-get? rewards { employee: employee, period: period }) ERR-NO-REWARDS-AVAILABLE))
    (bonus-amount (get bonus-amount reward-data))
  )
    (asserts! (is-eq tx-sender employee) ERR-NOT-AUTHORIZED)
    (asserts! (not (get claimed reward-data)) ERR-REWARD-ALREADY-CLAIMED)
    (asserts! (> bonus-amount u0) ERR-NO-REWARDS-AVAILABLE)
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) bonus-amount) ERR-INSUFFICIENT-CONTRACT-BALANCE)
    
    ;; Transfer STX bonus to employee
    (try! (as-contract (stx-transfer? bonus-amount tx-sender employee)))
    
    ;; Update reward status
    (map-set rewards
      { employee: employee, period: period }
      (merge reward-data { claimed: true, claim-block: stacks-block-height })
    )
    
    ;; Update employee total rewards
    (map-set employees
      { employee: employee }
      (merge employee-data { 
        total-rewards-earned: (+ (get total-rewards-earned employee-data) bonus-amount) 
      })
    )
    
    (ok bonus-amount)
  )
)

;; Private helper functions
(define-private (calculate-bonus (employee principal) (period uint))
  (let (
    (target-data (unwrap! (map-get? targets { employee: employee, period: period }) ERR-TARGETS-NOT-SET))
    (perf-data (unwrap! (map-get? performance { employee: employee, period: period }) ERR-INVALID-PERFORMANCE))
    (quality-score (get quality-score perf-data))
    (delivery-score (get delivery-score perf-data))
    (quality-target (get quality-target target-data))
    (delivery-target (get delivery-target target-data))
    (bonus-multiplier (get bonus-multiplier target-data))
  )
    (if (and (>= quality-score quality-target) (>= delivery-score delivery-target))
      (let (
        (quality-bonus (/ (* BASE-BONUS-AMOUNT QUALITY-WEIGHT quality-score) (* u100 u100)))
        (delivery-bonus (/ (* BASE-BONUS-AMOUNT DELIVERY-WEIGHT delivery-score) (* u100 u100)))
        (base-bonus (+ quality-bonus delivery-bonus))
        (final-bonus (/ (* base-bonus bonus-multiplier) u100))
        (performance-mult (+ (/ (* quality-score u100) quality-target) (/ (* delivery-score u100) delivery-target)))
      )
        (ok {
          bonus-amount: final-bonus,
          quality-bonus: quality-bonus,
          delivery-bonus: delivery-bonus,
          performance-multiplier: performance-mult
        })
      )
      (ok {
        bonus-amount: u0,
        quality-bonus: u0,
        delivery-bonus: u0,
        performance-multiplier: u0
      })
    )
  )
)

(define-private (get-current-period)
  (/ stacks-block-height BLOCKS-PER-PERIOD)
)

;; Read-only functions
(define-read-only (get-employee-info (employee principal))
  (map-get? employees { employee: employee })
)

(define-read-only (get-employee-targets (employee principal) (period uint))
  (map-get? targets { employee: employee, period: period })
)

(define-read-only (get-employee-performance (employee principal) (period uint))
  (map-get? performance { employee: employee, period: period })
)

(define-read-only (get-employee-rewards (employee principal) (period uint))
  (map-get? rewards { employee: employee, period: period })
)

(define-read-only (get-available-bonus (employee principal) (period uint))
  (match (calculate-bonus employee period)
    success (some (get bonus-amount success))
    error none
  )
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-current-period-info)
  {
    current-period: (get-current-period),
    current-block: stacks-block-height,
    blocks-per-period: BLOCKS-PER-PERIOD
  }
)

(define-read-only (is-employee-registered (employee principal))
  (is-some (map-get? employees { employee: employee }))
)

(define-read-only (get-performance-summary (employee principal) (period uint))
  (let (
    (perf-data (map-get? performance { employee: employee, period: period }))
    (target-data (map-get? targets { employee: employee, period: period }))
  )
    (if (and (is-some perf-data) (is-some target-data))
      (let (
        (perf-info (unwrap-panic perf-data))
        (target-info (unwrap-panic target-data))
      )
        (some {
          performance: perf-info,
          targets: target-info,
          targets-met: (and 
            (>= (get quality-score perf-info) (get quality-target target-info))
            (>= (get delivery-score perf-info) (get delivery-target target-info))
          ),
          quality-achievement: (if (> (get quality-target target-info) u0)
            (/ (* (get quality-score perf-info) u100) (get quality-target target-info))
            u0
          ),
          delivery-achievement: (if (> (get delivery-target target-info) u0)
            (/ (* (get delivery-score perf-info) u100) (get delivery-target target-info))
            u0
          )
        })
      )
      none
    )
  )
)

;; Public funding function for contract
(define-public (fund-contract (amount uint))
  (begin
    (asserts! (> amount u0) (err u110))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok true)
  )
)

;; Emergency functions
(define-public (deactivate-employee (employee principal))
  (let ((employee-data (unwrap! (map-get? employees { employee: employee }) ERR-EMPLOYEE-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set employees
      { employee: employee }
      (merge employee-data { active: false })
    )
    (ok true)
  )
)

(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (stx-get-balance (as-contract tx-sender))) ERR-INSUFFICIENT-CONTRACT-BALANCE)
    (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER))
  )
)
