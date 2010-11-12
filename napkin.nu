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
  
  (- (id) evaluateBlock:(id)block is
    (unless (block @object)
      (then
        (set d "block returned a falsy value")
        (throw ((BaconError alloc) initWithDescription:d))
      )
    )
  )
  
  ; (- (id) equal:(id)value is
  ;   (unless (eq @object value)
  ;     (set d "`#{@object}' does not equal `#{value}'")
  ;     (throw ((BaconError alloc) initWithDescription:d))
  ;   )
  ; )
  
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
        (else nil)
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
(function fail ()
  (do (block)
    ((`(eval block) should) raise:"BaconError")
    t
  )
)

(describe "An instance of Should" `(
  ; (it "raises an exception if the assertion fails" (do ()
  ;   (set x ((Should alloc) initWithObject:"foo"))
  ;   (x equal:"bar")
  ; ))
  ; 
  ; (it "does not raise an exception if the assertion passes" (do ()
  ;   (set x ((Should alloc) initWithObject:"foo"))
  ;   (x equal:"foo")
  ; ))
  ; 
  ; (it "catches any type of exception" (do ()
  ;   (throw "ohnoes")
  ; ))
  
  (it "checks if the given block satisfies" (do ()
    (("foo" should) satisfy:"pass" block:(do (x) (eq x "foo"))) ; should pass
    ;(("foo" should) satisfy:(do (x) (eq x "bar"))) ; should fail
    ((("foo" should) not) satisfy:"pass" block:(do (x) (eq x "bar"))) ; should pass
    ;((("foo" should) not) satisfy:(do (x) (eq x "foo"))) ; should fail
  ))
  
  ; (it "negates an assertion" (do ()
  ;   ((("foo" should) not) equal:"bar")
  ; ))
  
  ; (it "extends NSObject to return a Should instance, wrapping that object" (do ()
  ;   (("foo" should) equal:"foo")
  ; ))
  
  (it "takes a block that's to be called with the `object', the return value indicates success or failure" (do ()
    ("foo" should:(do (string) (eq string "foo")))
    (("foo" should) not:(do (string) (eq string "bar")))
    ;("foo" should:(do (string) (eq string "bar")))
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