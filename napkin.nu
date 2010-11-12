(class Context is NSObject
  (ivar (id) name
        (id) requirements)
  
  (- (id) initWithName:(id)name requirements:(id)requirements is
    (self init)
    (set @name name)
    (set @requirements requirements)
    self
  )
  
  (- (id) run is
    (puts @name)
    (@requirements each: (do (x) (eval x)))
    (print "\n")
  )
  
  (- (id) requirement:(id)description block:(id)block is
    (print "- #{description}")
    (try
      (eval block)
      (catch (e)
        (if (eq (e class) BaconError)
          (then (print " [Failed: #{(e reason)}]")) ; TODO this must be reported on exit
          ;(else (print " [Failed: #{(e reason)}]"))
          (else (print " [Failed]"))
        )
      )
    )
    (print "\n")
  )
)

; TODO How should I subclass NSException?
(class BaconError is NSObject
  (ivar (id) description)
  
  (- (id) initWithDescription:(id)description is
    (self init)
    (set @description description)
    self
  )
  
  (- (id) name is "BaconError")
  (- (id) reason is @description)
)

(class Should is NSObject
  (ivar (id) object
        (id) negated
  )
  
  (- (id) initWithObject:(id)object is
    (self init) ;; TODO check if it's nil
    ;; (puts (object description))
    (set @object object)
    (set @negated nil)
    self
  )
  
  (- (id) not is
    ;(puts "called not")
    (set @negated t)
    self
  )
  
  (- (id) not:(id)block is
    ;(puts "called not:")
    (set @negated t)
    (self satisfy:"satisfy the given block" block:block)
  )
  
  (- (id) satisfy:(id)description block:(id)block is
    (if (@negated)
      (then (set d "expected `#{@object}' to not #{description}"))
      (else (set d "expected `#{@object}' to #{description}"))
    )
    (set result (block @object))
    ;(puts "result is: #{result}")
    (if (result)
      (then
        (if (@negated)
          (throw ((BaconError alloc) initWithDescription:d))
        )
      )
      (else
        (unless (@negated)
          (throw ((BaconError alloc) initWithDescription:d))
        )
      )
    )
  )
  
  (- (id) equal:(id)value is
    (self satisfy:"equal `#{value}'" block:(do (object)
      (eq object value)
    ))
  )
  
  (- (id) raise:(id)exceptionName is
    (self satisfy:"raise an exception of type `#{exceptionName}'" block:(do (object)
      (try
        (eval object)
        (catch (e)
          (eq (e name) exceptionName)
        )
      )
    ))
  )
)

(class NSObject
  (- (id) should is ((Should alloc) initWithObject:self))
  (- (id) should:(id)block is (((Should alloc) initWithObject:self) satisfy:"satisfy the given block" block:block))
)

; TODO does a macro have an advantage here?
(function describe (name requirements) (((Context alloc) initWithName:name requirements:requirements) run))

(macro-0 it
  (set __description (car margs))
  (set __block (cdr margs))
  (self requirement:__description block:__block)
)

; Hooray for meta-testing.
; (function succeed
;   (do (block)
;     (((`(eval block) should) not) raise:"BaconError")
;     t
;   )
; )
; 
; (function fail ()
;   (do (block)
;     ((`(eval block) should) raise:"BaconError")
;     t
;   )
; )

(describe "An instance of Should" `(
  (it "raises a BaconError if the assertion fails" (do ()
    (set block `((((Should alloc) initWithObject:"foo") equal:"bar")))
    ((block should) raise:"BaconError")
  ))
  
  (it "does not raise an exception if the assertion passes" (do ()
    (set block `((((Should alloc) initWithObject:"foo") equal:"foo")))
    (((block should) not) raise:"BaconError")
  ))
  
  ; (it "catches any type of exception" (do ()
  ;   (throw "ohnoes")
  ; ))
  
  (it "checks if the given block satisfies" (do ()
    ; should pass
    (("foo" should) satisfy:"pass" block:(do (x) (eq x "foo")))
    ; should fail
    (set block `(("foo" should) satisfy:"fail" block:(do (x) (eq x "bar"))))
    ((block should) raise:"BaconError")
    
    ; should pass
    ((("foo" should) not) satisfy:"pass" block:(do (x) (eq x "bar")))
    ; should fail
    (set block `((("foo" should) not) satisfy:"fail" block:(do (x) (eq x "foo"))))
    ((block should) raise:"BaconError")
  ))
  
  (it "negates an assertion" (do ()
    ((("foo" should) not) equal:"bar")
  ))
  
  (it "checks for equality" (do ()
    (("foo" should) equal:"foo")
    ((("foo" should) not) equal:"bar")
  ))
  
  (it "checks if a specified exception is raised" (do ()
    ((`((NSArray array) objectAtIndex:0) should) raise:"NSRangeException")
    (((`((NSArray array) objectAtIndex:0) should) not) raise:"SomeRandomException")
  ))
))

(describe "NSObject, concerning Bacon extensions" `(
  (it "returns a Should instance, wrapping that object" (do ()
    (("foo" should) equal:"foo")
  ))
  
  (it "takes a block that's to be called with the `object', the return value indicates success or failure" (do ()
    ("foo" should:(do (string) (eq string "foo")))
    (("foo" should) not:(do (string) (eq string "bar")))
    ; should fail
    (set block `("foo" should:(do (string) (eq string "bar"))))
    ((block should) raise:"BaconError")
  ))
))