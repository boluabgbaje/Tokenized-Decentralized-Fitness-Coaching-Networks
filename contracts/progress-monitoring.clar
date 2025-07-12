;; Progress Monitoring Contract
;; Tracks workout completion and physical improvements

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_WORKOUT_NOT_FOUND (err u201))
(define-constant ERR_INVALID_INPUT (err u202))
(define-constant ERR_MEASUREMENT_NOT_FOUND (err u203))

;; Data Variables
(define-data-var next-workout-id uint u1)
(define-data-var next-measurement-id uint u1)

;; Data Maps
(define-map workouts
  { workout-id: uint }
  {
    user: principal,
    workout-type: (string-ascii 50),
    duration: uint,
    calories-burned: uint,
    exercises: (string-ascii 500),
    intensity: uint,
    date: uint,
    completed: bool
  }
)

(define-map measurements
  { measurement-id: uint }
  {
    user: principal,
    measurement-type: (string-ascii 50),
    value: uint,
    unit: (string-ascii 20),
    date: uint,
    notes: (string-ascii 200)
  }
)

(define-map user-workouts
  { user: principal }
  { workout-ids: (list 100 uint) }
)

(define-map user-measurements
  { user: principal }
  { measurement-ids: (list 100 uint) }
)

(define-map workout-streaks
  { user: principal }
  {
    current-streak: uint,
    longest-streak: uint,
    last-workout-date: uint
  }
)

(define-map achievements
  { user: principal, achievement-type: (string-ascii 50) }
  {
    unlocked: bool,
    date-unlocked: uint,
    progress: uint
  }
)

;; Public Functions

;; Log a workout session
(define-public (log-workout (workout-type (string-ascii 50)) (duration uint) (calories-burned uint) (exercises (string-ascii 500)) (intensity uint))
  (let
    (
      (workout-id (var-get next-workout-id))
      (user tx-sender)
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len workout-type) u0) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (asserts! (<= intensity u10) ERR_INVALID_INPUT)

    ;; Create workout record
    (map-set workouts
      { workout-id: workout-id }
      {
        user: user,
        workout-type: workout-type,
        duration: duration,
        calories-burned: calories-burned,
        exercises: exercises,
        intensity: intensity,
        date: current-time,
        completed: true
      }
    )

    ;; Update user's workout list
    (let
      (
        (current-workouts (default-to (list) (get workout-ids (map-get? user-workouts { user: user }))))
      )
      (map-set user-workouts
        { user: user }
        { workout-ids: (unwrap-panic (as-max-len? (append current-workouts workout-id) u100)) }
      )
    )

    ;; Update workout streak
    (update-workout-streak user current-time)

    ;; Increment workout ID counter
    (var-set next-workout-id (+ workout-id u1))

    (ok workout-id)
  )
)

;; Record a physical measurement
(define-public (record-measurement (measurement-type (string-ascii 50)) (value uint) (unit (string-ascii 20)) (notes (string-ascii 200)))
  (let
    (
      (measurement-id (var-get next-measurement-id))
      (user tx-sender)
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len measurement-type) u0) ERR_INVALID_INPUT)
    (asserts! (> value u0) ERR_INVALID_INPUT)
    (asserts! (> (len unit) u0) ERR_INVALID_INPUT)

    ;; Create measurement record
    (map-set measurements
      { measurement-id: measurement-id }
      {
        user: user,
        measurement-type: measurement-type,
        value: value,
        unit: unit,
        date: current-time,
        notes: notes
      }
    )

    ;; Update user's measurement list
    (let
      (
        (current-measurements (default-to (list) (get measurement-ids (map-get? user-measurements { user: user }))))
      )
      (map-set user-measurements
        { user: user }
        { measurement-ids: (unwrap-panic (as-max-len? (append current-measurements measurement-id) u100)) }
      )
    )

    ;; Increment measurement ID counter
    (var-set next-measurement-id (+ measurement-id u1))

    (ok measurement-id)
  )
)

;; Update workout completion status
(define-public (update-workout-status (workout-id uint) (completed bool))
  (let
    (
      (workout (unwrap! (map-get? workouts { workout-id: workout-id }) ERR_WORKOUT_NOT_FOUND))
      (user tx-sender)
    )
    (asserts! (is-eq (get user workout) user) ERR_UNAUTHORIZED)

    (map-set workouts
      { workout-id: workout-id }
      (merge workout { completed: completed })
    )

    (ok true)
  )
)

;; Unlock achievement
(define-public (unlock-achievement (achievement-type (string-ascii 50)) (progress uint))
  (let
    (
      (user tx-sender)
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (map-set achievements
      { user: user, achievement-type: achievement-type }
      {
        unlocked: true,
        date-unlocked: current-time,
        progress: progress
      }
    )

    (ok true)
  )
)

;; Private Functions

;; Update workout streak for user
(define-private (update-workout-streak (user principal) (workout-date uint))
  (let
    (
      (current-streak-data (default-to { current-streak: u0, longest-streak: u0, last-workout-date: u0 }
                                      (map-get? workout-streaks { user: user })))
      (last-date (get last-workout-date current-streak-data))
      (current-streak (get current-streak current-streak-data))
      (longest-streak (get longest-streak current-streak-data))
      (one-day u86400) ;; seconds in a day
    )
    (let
      (
        (days-since-last (if (> last-date u0) (/ (- workout-date last-date) one-day) u0))
        (new-streak (if (or (is-eq last-date u0) (<= days-since-last u1))
                       (+ current-streak u1)
                       u1))
        (new-longest (if (> new-streak longest-streak) new-streak longest-streak))
      )
      (map-set workout-streaks
        { user: user }
        {
          current-streak: new-streak,
          longest-streak: new-longest,
          last-workout-date: workout-date
        }
      )
    )
  )
)

;; Read-only Functions

;; Get workout details
(define-read-only (get-workout (workout-id uint))
  (map-get? workouts { workout-id: workout-id })
)

;; Get measurement details
(define-read-only (get-measurement (measurement-id uint))
  (map-get? measurements { measurement-id: measurement-id })
)

;; Get user's workouts
(define-read-only (get-user-workouts (user principal))
  (map-get? user-workouts { user: user })
)

;; Get user's measurements
(define-read-only (get-user-measurements (user principal))
  (map-get? user-measurements { user: user })
)

;; Get workout streak
(define-read-only (get-workout-streak (user principal))
  (map-get? workout-streaks { user: user })
)

;; Get achievement status
(define-read-only (get-achievement (user principal) (achievement-type (string-ascii 50)))
  (map-get? achievements { user: user, achievement-type: achievement-type })
)

;; Calculate total calories burned
(define-read-only (get-total-calories-burned (user principal))
  (match (map-get? user-workouts { user: user })
    user-workout-data
      (let
        (
          (workout-ids (get workout-ids user-workout-data))
        )
        (ok (fold calculate-calories workout-ids u0))
      )
    (ok u0)
  )
)

;; Helper function for calorie calculation
(define-private (calculate-calories (workout-id uint) (total uint))
  (match (map-get? workouts { workout-id: workout-id })
    workout (+ total (get calories-burned workout))
    total
  )
)

;; Get total workout count
(define-read-only (get-total-workouts)
  (- (var-get next-workout-id) u1)
)

;; Get total measurements count
(define-read-only (get-total-measurements)
  (- (var-get next-measurement-id) u1)
)
