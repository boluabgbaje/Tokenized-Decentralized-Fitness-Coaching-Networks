;; Nutrition Guidance Contract
;; Provides dietary recommendations and meal planning

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_MEAL_NOT_FOUND (err u301))
(define-constant ERR_INVALID_INPUT (err u302))
(define-constant ERR_PLAN_NOT_FOUND (err u303))

;; Data Variables
(define-data-var next-meal-id uint u1)
(define-data-var next-plan-id uint u1)

;; Data Maps
(define-map meals
  { meal-id: uint }
  {
    user: principal,
    meal-name: (string-ascii 100),
    meal-type: (string-ascii 20),
    calories: uint,
    protein: uint,
    carbs: uint,
    fat: uint,
    fiber: uint,
    ingredients: (string-ascii 500),
    date: uint,
    logged: bool
  }
)

(define-map meal-plans
  { plan-id: uint }
  {
    user: principal,
    plan-name: (string-ascii 100),
    description: (string-ascii 300),
    daily-calories: uint,
    daily-protein: uint,
    daily-carbs: uint,
    daily-fat: uint,
    duration-days: uint,
    created-date: uint,
    active: bool
  }
)

(define-map user-meals
  { user: principal }
  { meal-ids: (list 200 uint) }
)

(define-map user-plans
  { user: principal }
  { plan-ids: (list 20 uint) }
)

(define-map dietary-preferences
  { user: principal }
  {
    diet-type: (string-ascii 50),
    allergies: (string-ascii 200),
    restrictions: (string-ascii 200),
    calorie-goal: uint,
    protein-goal: uint,
    carb-goal: uint,
    fat-goal: uint
  }
)

(define-map nutrition-tracking
  { user: principal, date: uint }
  {
    total-calories: uint,
    total-protein: uint,
    total-carbs: uint,
    total-fat: uint,
    total-fiber: uint,
    meals-logged: uint
  }
)

;; Public Functions

;; Log a meal
(define-public (log-meal (meal-name (string-ascii 100)) (meal-type (string-ascii 20)) (calories uint) (protein uint) (carbs uint) (fat uint) (fiber uint) (ingredients (string-ascii 500)))
  (let
    (
      (meal-id (var-get next-meal-id))
      (user tx-sender)
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len meal-name) u0) ERR_INVALID_INPUT)
    (asserts! (> (len meal-type) u0) ERR_INVALID_INPUT)
    (asserts! (> calories u0) ERR_INVALID_INPUT)

    ;; Create meal record
    (map-set meals
      { meal-id: meal-id }
      {
        user: user,
        meal-name: meal-name,
        meal-type: meal-type,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        ingredients: ingredients,
        date: current-time,
        logged: true
      }
    )

    ;; Update user's meal list
    (let
      (
        (current-meals (default-to (list) (get meal-ids (map-get? user-meals { user: user }))))
      )
      (map-set user-meals
        { user: user }
        { meal-ids: (unwrap-panic (as-max-len? (append current-meals meal-id) u200)) }
      )
    )

    ;; Update daily nutrition tracking
    (update-daily-nutrition user current-time calories protein carbs fat fiber)

    ;; Increment meal ID counter
    (var-set next-meal-id (+ meal-id u1))

    (ok meal-id)
  )
)

;; Create a meal plan
(define-public (create-meal-plan (plan-name (string-ascii 100)) (description (string-ascii 300)) (daily-calories uint) (daily-protein uint) (daily-carbs uint) (daily-fat uint) (duration-days uint))
  (let
    (
      (plan-id (var-get next-plan-id))
      (user tx-sender)
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len plan-name) u0) ERR_INVALID_INPUT)
    (asserts! (> daily-calories u0) ERR_INVALID_INPUT)
    (asserts! (> duration-days u0) ERR_INVALID_INPUT)

    ;; Create meal plan
    (map-set meal-plans
      { plan-id: plan-id }
      {
        user: user,
        plan-name: plan-name,
        description: description,
        daily-calories: daily-calories,
        daily-protein: daily-protein,
        daily-carbs: daily-carbs,
        daily-fat: daily-fat,
        duration-days: duration-days,
        created-date: current-time,
        active: true
      }
    )

    ;; Update user's plan list
    (let
      (
        (current-plans (default-to (list) (get plan-ids (map-get? user-plans { user: user }))))
      )
      (map-set user-plans
        { user: user }
        { plan-ids: (unwrap-panic (as-max-len? (append current-plans plan-id) u20)) }
      )
    )

    ;; Increment plan ID counter
    (var-set next-plan-id (+ plan-id u1))

    (ok plan-id)
  )
)

;; Set dietary preferences
(define-public (set-dietary-preferences (diet-type (string-ascii 50)) (allergies (string-ascii 200)) (restrictions (string-ascii 200)) (calorie-goal uint) (protein-goal uint) (carb-goal uint) (fat-goal uint))
  (let
    (
      (user tx-sender)
    )
    (asserts! (> calorie-goal u0) ERR_INVALID_INPUT)

    (map-set dietary-preferences
      { user: user }
      {
        diet-type: diet-type,
        allergies: allergies,
        restrictions: restrictions,
        calorie-goal: calorie-goal,
        protein-goal: protein-goal,
        carb-goal: carb-goal,
        fat-goal: fat-goal
      }
    )

    (ok true)
  )
)

;; Update meal plan status
(define-public (update-plan-status (plan-id uint) (active bool))
  (let
    (
      (plan (unwrap! (map-get? meal-plans { plan-id: plan-id }) ERR_PLAN_NOT_FOUND))
      (user tx-sender)
    )
    (asserts! (is-eq (get user plan) user) ERR_UNAUTHORIZED)

    (map-set meal-plans
      { plan-id: plan-id }
      (merge plan { active: active })
    )

    (ok true)
  )
)

;; Delete meal
(define-public (delete-meal (meal-id uint))
  (let
    (
      (meal (unwrap! (map-get? meals { meal-id: meal-id }) ERR_MEAL_NOT_FOUND))
      (user tx-sender)
    )
    (asserts! (is-eq (get user meal) user) ERR_UNAUTHORIZED)

    (map-delete meals { meal-id: meal-id })

    (ok true)
  )
)

;; Private Functions

;; Update daily nutrition tracking
(define-private (update-daily-nutrition (user principal) (meal-time uint) (calories uint) (protein uint) (carbs uint) (fat uint) (fiber uint))
  (let
    (
      (day-start (- meal-time (mod meal-time u86400))) ;; Start of the day
      (current-tracking (default-to
        { total-calories: u0, total-protein: u0, total-carbs: u0, total-fat: u0, total-fiber: u0, meals-logged: u0 }
        (map-get? nutrition-tracking { user: user, date: day-start })))
    )
    (map-set nutrition-tracking
      { user: user, date: day-start }
      {
        total-calories: (+ (get total-calories current-tracking) calories),
        total-protein: (+ (get total-protein current-tracking) protein),
        total-carbs: (+ (get total-carbs current-tracking) carbs),
        total-fat: (+ (get total-fat current-tracking) fat),
        total-fiber: (+ (get total-fiber current-tracking) fiber),
        meals-logged: (+ (get meals-logged current-tracking) u1)
      }
    )
  )
)

;; Read-only Functions

;; Get meal details
(define-read-only (get-meal (meal-id uint))
  (map-get? meals { meal-id: meal-id })
)

;; Get meal plan details
(define-read-only (get-meal-plan (plan-id uint))
  (map-get? meal-plans { plan-id: plan-id })
)

;; Get user's meals
(define-read-only (get-user-meals (user principal))
  (map-get? user-meals { user: user })
)

;; Get user's meal plans
(define-read-only (get-user-plans (user principal))
  (map-get? user-plans { user: user })
)

;; Get dietary preferences
(define-read-only (get-dietary-preferences (user principal))
  (map-get? dietary-preferences { user: user })
)

;; Get daily nutrition tracking
(define-read-only (get-daily-nutrition (user principal) (date uint))
  (map-get? nutrition-tracking { user: user, date: date })
)

;; Calculate calorie deficit/surplus
(define-read-only (get-calorie-balance (user principal) (date uint))
  (match (map-get? dietary-preferences { user: user })
    prefs
      (match (map-get? nutrition-tracking { user: user, date: date })
        tracking
          (let
            (
              (goal (get calorie-goal prefs))
              (consumed (get total-calories tracking))
            )
            (ok (if (> consumed goal) (- consumed goal) (- goal consumed)))
          )
        (ok u0)
      )
    ERR_INVALID_INPUT
  )
)

;; Check if daily goals are met
(define-read-only (are-daily-goals-met (user principal) (date uint))
  (match (map-get? dietary-preferences { user: user })
    prefs
      (match (map-get? nutrition-tracking { user: user, date: date })
        tracking
          (let
            (
              (calorie-met (>= (get total-calories tracking) (get calorie-goal prefs)))
              (protein-met (>= (get total-protein tracking) (get protein-goal prefs)))
            )
            (ok (and calorie-met protein-met))
          )
        (ok false)
      )
    ERR_INVALID_INPUT
  )
)

;; Get total meals count
(define-read-only (get-total-meals)
  (- (var-get next-meal-id) u1)
)

;; Get total plans count
(define-read-only (get-total-plans)
  (- (var-get next-plan-id) u1)
)
