(class BaconSummary is NSObject
  (ivar (id) counters
        (id) errorLog
  )
  
  (- (id) init is
    (super init)
    (set @errorLog "")
    (set @counters (NSMutableDictionary dictionaryWithList:`("specifications" 0 "requirements" 0 "failures" 0 "errors" 0)))
    (self)
  )
  
  (- (id) specifications is
    (@counters valueForKey:"specifications")
  )
  
  (- (id) addSpecification is
    (@counters setValue:(+ (self specifications) 1) forKey:"specifications")
  )
  
  (- (id) requirements is
    (@counters valueForKey:"requirements")
  )
  
  (- (id) addRequirement is
    (@counters setValue:(+ (self requirements) 1) forKey:"requirements")
  )
  
  (- (id) failures is
    (@counters valueForKey:"failures")
  )
  
  (- (id) addFailure is
    (@counters setValue:(+ (self failures) 1) forKey:"failures")
  )
  
  (- (id) errors is
    (@counters valueForKey:"errors")
  )
  
  (- (id) addError is
    (@counters setValue:(+ (self errors) 1) forKey:"errors")
  )
  
  (- (id) addToErrorLog:(id)e context:(id)name specification:(id)description type:(id)type is
    (@errorLog appendString:"#{name} - #{description}: ")
    (if (e respondsToSelector:"reason")
      (then (@errorLog appendString:(e reason)))
      (else (@errorLog appendString:(e description)))
    )
    (@errorLog appendString:"#{type}\n")
  )
  
  (- (id) print is
    (print "\n")
    (puts @errorLog)
    (puts "#{(self specifications)} specifications (#{(self requirements)} requirements), #{(self failures)} failures, #{(self errors)} errors")
  )
)

(set $BaconSummary ((BaconSummary alloc) init))

(class Context is NSObject
  ; use the dynamic `ivars' so the user can add ivars in before/after
  (ivars (id) name
         (id) before
         (id) after
         (id) requirements)
  
  (- (id) initWithName:(id)name requirements:(id)requirements is
    (self init)
    (set @before (NSMutableArray array))
    (set @after (NSMutableArray array))
    (set @name name)
    (set @requirements requirements)
    self
  )
  
  (- (id) childContextWithName:(id)childName requirements:(id)requirements is
    (set child ((Context alloc) initWithName:"#{@name} #{childName}" requirements:requirements))
    (@before each: (do (x) (child before:x)))
    (@after each: (do (x) (child after:x)))
    child
  )
  
  (- (id) run is
    (print "\n")
    (puts @name)
    (@requirements each: (do (x) (eval x)))
  )
  
  (- (id) before:(id)block is
    (@before addObject:block)
  )
  
  (- (id) after:(id)block is
    (@after addObject:block)
  )
  
  (- (id) requirement:(id)description block:(id)block is
    ($BaconSummary addSpecification)
    (print "- #{description}")
    
    (try
      (try ; wrap before/requirement/after
        (@before each: (do (x) (eval x)))
        (eval block)
        (catch (e)
          ; don't allow after filters to throw, as it could result in an endless loop
          (self runAfterFilterAndThrow:nil)
          (throw e)
        )
        ; ensure the after filters are always run, these however may throw, as we already ran the requirement
        (self runAfterFilterAndThrow:t)
      )
      (catch (e) ; now really handle the bubbled exception
        (if (eq (e class) BaconError)
          (then
            ($BaconSummary addFailure)
            (set type " [FAILURE]")
          )
          (else
            ($BaconSummary addError)
            (set type " [ERROR]")
          )
        )
        (print type)
        ($BaconSummary addToErrorLog:e context:@name specification:description type:type)
      )
    )
    
    (print "\n")
  )
  
  (- (id) runAfterFilterAndThrow:(id)shouldThrow is
    (try
      (@after each: (do (x) (eval x)))
      (catch (e)
        (if (shouldThrow) (throw e))
      )
    )
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
    ($BaconSummary addRequirement)
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
  
  (- (id) raise is
    (set result nil)
    (self satisfy:"raise any exception" block:(do (object)
      (try
        (eval object)
        (catch (e)
          (set result e)
          t
        )
        nil
      )
    ))
    result
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
  
  (- (id) handleUnknownMessage:(id)methodName withContext:(id)context is
    (set name "#{(methodName lastObject)}")
    (set predicate "is#{((name substringToIndex:1) uppercaseString)}#{(name substringFromIndex:1)}")
    ;(puts "Predicate version: #{predicate}")
    (if (@object respondsToSelector:predicate)
      (then
        (self satisfy:"be a #{name}" block:(do (object)
          ;(set r (eval (object predicate))) ; TODO better way to send and have return value work?
          ;(set r (object sendMessage:(eval "`(#{predicate})") withContext:context))
          (set r (object valueForKey:predicate))
          (puts r)
          r
        ))
      )
      (else
        (super handleUnknownMessage:methodName withContext:context)
      )
    )
  )
)

(class NSObject
  (- (id) should is ((Should alloc) initWithObject:self))
  (- (id) should:(id)block is (((Should alloc) initWithObject:self) satisfy:"satisfy the given block" block:block))
)

(macro-0 describe
  (set __name (car margs))
  (set __requirements (eval (cdr margs)))
  (try
    (set parent self)
    ((parent childContextWithName:__name requirements:__requirements) run)
    (catch (e)
      (if (eq (e reason) "undefined symbol self while evaluating expression (set parent self)")
        (then
          ; not running inside a context
          (((Context alloc) initWithName:__name requirements:__requirements) run)
        )
        ; another type of exception occured
        (else (throw e))
      )
    )
  )
)

(macro-0 it
  (set __description (car margs))
  (set __block (cdr margs))
  (self requirement:__description block:__block)
)

; TODO for some reason this only works if the macro accepts an arg like string, before the block.
(macro-0 before
  (set __when (car margs))
  (set __block (cdr margs))
  (self before:__block)
)
(macro-0 after
  (set __when (car margs))
  (set __block (cdr margs))
  (self after:__block)
)

; shared contexts

(set $BaconShared (NSMutableDictionary dictionary))

(macro-0 shared
  (set __name (car margs))
  (set __requirements (eval (cdr margs)))
  ($BaconShared setValue:__requirements forKey:__name)
)

(macro-0 behaves_like
  (set __name (car margs))
  (set context ($BaconShared valueForKey:__name))
  (if (context)
    ; each requirement is a complete `it' block
    (then (context each: (do (requirement) (eval requirement))))
    (else (throw "No such context `#{__name}'"))
  )
)