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
          (else (print " [Failed: #{(e reason)}]"))
          ;(else (print " [Failed]"))
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
  
  (- (id) be is
    self
  )
  
  (- (id) be:(id)value is
    (self equal:value)
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
    (set result nil)
    (self satisfy:"raise an exception of type `#{exceptionName}'" block:(do (object)
      (try
        (eval object)
        (catch (e)
          (set result e)
          (eq (e name) exceptionName)
        )
      )
    ))
    result
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
(set succeed
  (do (block)
    (((block should) not) raise:"BaconError")
    t
  )
)

(set fail
  (do (block)
    ((block should) raise:"BaconError")
    t
  )
)

; Just some test constants
(set equalFoo (do (x) (eq x "foo")))
(set equalBar (do (x) (eq x "bar")))
(set aRequirement ("foo" should))
(set rangeException `((NSArray array) objectAtIndex:0))

(describe "An instance of Should" `(
  (it "raises a BaconError if the assertion fails" (do ()
    (`(("foo" should) equal:"bar") should:fail)
  ))
  
  (it "does not raise an exception if the assertion passes" (do ()
    (`(("foo" should) equal:"foo") should:succeed)
  ))
  
  ; (it "catches any type of exception" (do ()
  ;   (throw "ohnoes")
  ; ))
  
  (it "checks if the given block satisfies" (do ()
    (`(("foo" should) satisfy:"pass" block:equalFoo) should:succeed)
    (`(("foo" should) satisfy:"fail" block:equalBar) should:fail)
    (`((("foo" should) not) satisfy:"pass" block:equalBar) should:succeed)
    (`((("foo" should) not) satisfy:"fail" block:equalFoo) should:fail)
  ))
  
  (it "negates an assertion" (do ()
    ((("foo" should) not) equal:"bar")
  ))
  
  ; TODO probably does change the description of the requirement
  (it "has a `be' syntactic sugar method which does nothing but return the Should instance" (do ()
    (((aRequirement be) should) equal:aRequirement)
  ))
  
  ; TODO probably does change the description of the requirement
  (it "has a `be:' syntactic sugar method which checks for equality" (do ()
    (`(aRequirement be:"foo") should:succeed)
    (`(aRequirement be:"bar") should:fail)
  ))
  
  (it "checks for equality" (do ()
    (("foo" should) equal:"foo")
    ((("foo" should) not) equal:"bar")
  ))
  
  (it "checks if a specified exception is raised" (do ()
    ((rangeException should) raise:"NSRangeException")
    (((rangeException should) not) raise:"SomeRandomException")
  ))
  
  (it "returns the raised exception" (do ()
    (set e ((rangeException should) raise:"NSRangeException"))
    ((((e class) name) should) equal:"NuException")
    (((e name) should) equal:"NSRangeException")
  ))
))

(describe "NSObject, concerning Bacon extensions" `(
  (it "returns a Should instance, wrapping that object" (do ()
    (("foo" should) equal:"foo")
  ))
  
  (it "takes a block that's to be called with the `object', the return value indicates success or failure" (do ()
    (`("foo" should:equalFoo) should:succeed)
    (`("foo" should:equalBar) should:fail)
    (`(("foo" should) not:equalBar) should:succeed)
    (`(("foo" should) not:equalFoo) should:fail)
  ))
))