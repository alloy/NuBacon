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

(class BaconContext is NSObject
  ; use the dynamic `ivars' so the user can add ivars in before/after
  (ivars (id) name
         (id) before
         (id) after
         (id) requirements
         (id) printedName)
  
  (- (id) initWithName:(id)name requirements:(id)requirements is
    (self init)
    (set @before (NSMutableArray array))
    (set @after (NSMutableArray array))
    (set @name name)
    (set @printedName nil)
    (set @requirements requirements)
    self
  )
  
  (- (id) childContextWithName:(id)childName requirements:(id)requirements is
    (set child ((BaconContext alloc) initWithName:"#{@name} #{childName}" requirements:requirements))
    ((@before list) each: (do (x) (child before:x)))
    ((@after list) each: (do (x) (child after:x)))
    child
  )
  
  (- (id) run is
    (@requirements each: (do (x) (eval x)))
  )
  
  (- (id) before:(id)block is
    (@before addObject:block)
  )
  
  (- (id) after:(id)block is
    (@after addObject:block)
  )
  
  (- (id) requirement:(id)description block:(id)block report:(id)report is
    (if (report)
      (unless (@printedName)
        (set @printedName t)
        (puts "\n#{@name}")
      )
      ($BaconSummary addSpecification)
      (print "- #{description}")
    )
    
    (set numberOfRequirementsBefore ($BaconSummary requirements))
    
    (try
      (try ; wrap before/requirement/after
        ((@before list) each: (do (x) (eval x)))
        (eval block)
        (if (eq numberOfRequirementsBefore ($BaconSummary requirements))
          ; the requirement did not contain any assertions, so it flunked
          (throw ((BaconError alloc) initWithDescription:"flunked"))
        )
        (catch (e)
          ; don't allow after filters to throw, as it could result in an endless loop
          (self runAfterFilterAndThrow:nil)
          (throw e)
        )
        ; ensure the after filters are always run, these however may throw, as we already ran the requirement
        (self runAfterFilterAndThrow:t)
      )
      (catch (e) ; now really handle the bubbled exception
        (if (report)
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
    )
    
    (if (report) (print "\n"))
  )
  
  (- (id) runAfterFilterAndThrow:(id)shouldThrow is
    (try
      ((@after list) each: (do (x) (eval x)))
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

(class BaconShould is NSObject
  (ivar (id) object
        (id) negated
        (id) descriptionBuffer
  )
  
  (- (id) initWithObject:(id)object is
    (self init) ;; TODO check if it's nil
    (set @object object)
    (set @negated nil)
    (set @descriptionBuffer "")
    self
  )
  
  (- (id) object is
    @object
  )
  
  (- (id) should is
    self
  )
  
  (- (id) should:(id)block is
    (self satisfy:nil block:block)
  )
  
  (- (id) not is
    (set @negated t)
    (@descriptionBuffer appendString:" not")
    self
  )
  
  (- (id) not:(id)block is
    (set @negated t)
    (@descriptionBuffer appendString:" not")
    (self satisfy:nil block:block)
  )
  
  (- (id) be is
    (@descriptionBuffer appendString:" be")
    self
  )
  
  (- (id) a is
    (@descriptionBuffer appendString:" a")
    self
  )
  
  (- (id) an is
    (@descriptionBuffer appendString:" an")
    self
  )
  
  (- (id) satisfy:(id)description block:(id)block is
    ($BaconSummary addRequirement)
    (unless description (set description "satisfy `#{block}'"))
    (set description "expected `#{@object}' to#{@descriptionBuffer} #{description}")
    (set passed (block @object))
    (if (passed)
      (then
        (if (@negated)
          (throw ((BaconError alloc) initWithDescription:description))
        )
      )
      (else
        (unless (@negated)
          (throw ((BaconError alloc) initWithDescription:description))
        )
      )
    )
  )
  
  (- (id) be:(id)value is
    (if (send value isKindOfClass:NuBlock)
      (then
        (self satisfy:"be `#{value}'" block:value)
      )
      (else
        (self satisfy:"be `#{value}'" block:(do (object)
          (eq object value)
        ))
      )
    )
  )
  
  (- (id) a:(id)value is
    (if (send value isKindOfClass:NuBlock)
      (then
        (self satisfy:"a `#{value}'" block:value)
      )
      (else
        (self satisfy:"a `#{value}'" block:(do (object)
          (eq object value)
        ))
      )
    )
  )
  
  (- (id) equal:(id)value is
    (self satisfy:"equal `#{value}'" block:(do (object)
      (eq object value)
    ))
  )
  
  (- (id) closeTo:(id)otherValue is
    (self closeTo:otherValue delta:0.00001)
  )
  
  (- (id) closeTo:(id)otherValue delta:(id)delta is
    (if (eq (otherValue class) NuCell)
      (then
        (set otherValues (otherValue array))
        (self satisfy:"close to `#{otherValue}'" block:(do (values)
          (set result t)
          (values eachWithIndex:(do (value index)
            (set otherValue (otherValues objectAtIndex:index))
            (set result (and result (and (>= otherValue (- value delta)) (<= otherValue (+ value delta)))))
          ))
          result
        ))
      )
      (else
        (self satisfy:"close to `#{otherValue}'" block:(do (value)
          (and (>= otherValue (- value delta)) (<= otherValue (+ value delta)))
        ))
      )
    )
  )
  
  (- (id) raise is
    (set result nil)
    (self satisfy:"raise any exception" block:(do (block)
      (try
        (call block)
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
    (self satisfy:"raise an exception of type `#{exceptionName}'" block:(do (block)
      (try
        (call block)
        (catch (e)
          (set result e)
          (eq (e name) exceptionName)
        )
      )
    ))
    result
  )
  
  (- (id) handleUnknownMessage:(id)methodName withContext:(id)context is
    (set name ((first methodName) stringValue))
    (set args (cdr methodName))
    (set description name)
    (if (args) (then (set description "#{description}#{args}")))
    (if (@object respondsToSelector:name)
      (then
        ; forward the message as-is
        (self satisfy:description block:(do (object)
          (object sendMessage:methodName withContext:context)
        ))
      )
      (else
        (set predicate "is#{((name substringToIndex:1) uppercaseString)}#{(name substringFromIndex:1)}")
        (if (@object respondsToSelector:predicate)
          (then
            ; forward the predicate version of the message with the args
            (self satisfy:description block:(do (object)
              (set symbol ((NuSymbolTable sharedSymbolTable) symbolWithString:predicate))
              (sendMessageWithSymbol object symbol (cdr methodName))
            ))
          )
          (else
            (set parts ((regex "([A-Z][a-z]*)") splitString:name))
            (set firstPart (parts objectAtIndex:0))
            (set firstPart (firstPart stringByAppendingString:"s"))
            (parts replaceObjectAtIndex:0 withObject:firstPart)
            (set thirdPersonForm (parts componentsJoinedByString:""))
            (if (@object respondsToSelector:thirdPersonForm)
              (then
                ; example: respondsToSelector: is matched as respondToSelector:
                (self satisfy:description block:(do (object)
                  (set symbol ((NuSymbolTable sharedSymbolTable) symbolWithString:thirdPersonForm))
                  (sendMessageWithSymbol object symbol (cdr methodName))
                ))
              )
              (else
                ; the object does not respond to any of the messages
                (super handleUnknownMessage:methodName withContext:context)
              )
            )
          )
        )
      )
    )
  )
)

(class NSObject
  (- (id) should is ((BaconShould alloc) initWithObject:self))
  (- (id) should:(id)block is (((BaconShould alloc) initWithObject:self) satisfy:nil block:block))
)

(macro-1 -> (*body)
  `(send (do () ,@*body) should)
)

; TODO figure out for real how this actually works and why getting the symbol in the macro doesn't work
; (set symbol ((NuSymbolTable sharedSymbolTable) symbolWithString:predicate))
(macro-1 sendMessageWithSymbol (object message args)
  `(,object ,(eval message) ,@(eval args))
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
          (((BaconContext alloc) initWithName:__name requirements:__requirements) run)
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
  (self requirement:__description block:__block report:t)
)

; TODO for some reason this only works if the macro accepts an arg like string, before the block.
(macro-0 before
  (self before:margs)
)
(macro-0 after
  (self after:margs)
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

