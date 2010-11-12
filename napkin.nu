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
  (ivar (id) object)
  
  (- (id) initWithObject:(id)object is
    (self init) ;; TODO check if it's nil
    ;; (puts (object description))
    (set @object object)
    self
  )
  
  (- (id) evaluateBlock:(id)block is
    (unless (block @object)
      (then
        (set d "block returned a falsy value")
        (throw ((BaconError alloc) initWithDescription:d))
      )
    )
  )
  
  (- (id) equal:(id)value is
    (unless (eq @object value)
      (set d "`#{@object}' does not equal `#{value}'")
      (throw ((BaconError alloc) initWithDescription:d))
    )
  )
  
  ; (- (id) ==:(id)value is
  ;   (eq @object value))
  
  (- (id) raise:(id)exceptionName is
    (try
      (eval @object)
      (catch (e)
        (unless (eq (e name) exceptionName)
          (then
            (set d "expected to raise an exception of type `#{exceptionName}', but was a `#{(e name)}'")
            (throw ((BaconError alloc) initWithDescription:d))
          )
        )
      )
    )
  )
)

(class NSObject
  (- (id) should is ((Should alloc) initWithObject:self))
  (- (id) should:(id)block is (((Should alloc) initWithObject:self) evaluateBlock:block))
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
  (it "raises an exception if the assertion fails" (do ()
    (set x ((Should alloc) initWithObject:"foo"))
    (x equal:"bar")
  ))
  
  (it "does not raise an exception if the assertion passes" (do ()
    (set x ((Should alloc) initWithObject:"foo"))
    (x equal:"foo")
  ))
  
  (it "catches any type of exception" (do ()
    (throw "ohnoes")
  ))
  
  (it "extends NSObject to return a Should instance, wrapping that object" (do ()
    (("foo" should) equal:"foo")
  ))
  
  (it "takes a list that's to be evaled, the return value indicates success or failure" (do ()
    ("foo" should:(do (string) (eq string "foo")))
    ;("foo" should:(do (string) (eq string "bar")))
  ))
  
  (it "compares for equality" (do ()
    (set x ((Should alloc) initWithObject:"foo"))
    (x equal:"foo")
  ))
  
  (it "checks if a specified exception is raised" (do ()
    ((`((NSArray array) objectAtIndex:0) should) raise:"NSRangeException")
  ))
))