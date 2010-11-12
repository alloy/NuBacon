(load "bacon.nu")

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
  
  (it "catches any type of exception so the spec suite can continue" (do ()
    (set requirement `(self requirement:"throws" block:`(throw "ohnoes") report:nil))
    ((((eval requirement) should) not) raise)
  ))
  
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
  
  (it "checks if any exception is raised" (do ()
    ((rangeException should) raise)
    (((`("foo") should) not) raise)
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
  
  (it "checks if the object has the method and if so forward the message" (do ()
    (`((("/an/absolute/path" should) be) isAbsolutePath) should:succeed)
    (`((("a/relative/path" should) be) isAbsolutePath) should:fail)
  ))
  
  (it "checks if the object has the predicate method and if so forward the message" (do ()
    (`((("/an/absolute/path" should) be) absolutePath) should:succeed)
    (`((("a/relative/path" should) be) absolutePath) should:fail)
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

(describe "before/after" `(
  (before "each" (do ()
    (set @a 1)
    (set @b 2)
  ))
  
  (before "each" (do ()
    (set @a 2)
  ))
  
  (after "each" (do ()
    ((@a should) equal:2)
    (set @a 3)
  ))
  
  (after "each" (do ()
    ((@a should) equal:3)
  ))
  
  (it "runs in the right order" (do ()
    ((@a should) equal:2)
    ((@b should) equal:2)
  ))
  
  (describe "when nested" `(
    (before "each" (do ()
      (set @c 5)
    ))
    
    (it "runs from higher level" (do ()
      ((@a should) equal:2)
      ((@b should) equal:2)
    ))
    
    (it "runs at the nested level" (do ()
      ((@c should) equal:5)
    ))
    
    (before "each" (do ()
      (set @a 5)
    ))
    
    (it "runs in the right order" (do ()
      ((@a should) equal:5)
      (set @a 2)
    ))
  ))
  
  (it "does not run from lower level" (do ()
    ((@c should) be:nil)
  ))
  
  (describe "when nested at a sibling level" (do ()
    (it "does not run from sibling level" (do ()
      ((@c should) be:nil)
    ))
  ))
))

(shared "a shared context" `(
  (it "gets called where it is included" (do ()
    ((t should) be:t)
  ))
))

(shared "another shared context" `(
  (it "can access data" (do ()
    ((@magic should) be:42)
  ))
))

(describe "shared/behaves_like" `(
  (behaves_like "a shared context")
  
  (it "raises when the context is not found" (do ()
    (set e ((`(behaves_like "whoops") should) raise))
    ((e should) equal:"No such context `whoops'")
  ))
  
  (behaves_like "a shared context")
  
  (before "each" (do ()
    (set @magic 42)
  ))
  
  (behaves_like "another shared context")
))

($BaconSummary print)