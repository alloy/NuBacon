(class BaconRequirement is NSObject
  (ivars (id) context
         (id) description
         (id) block
         (id) postponedBlock
         (id) hasPostponedBlock
         (id) before
         (id) after
         (id) report)

  (- (id) initWithContext:(id)context description:(id)description block:(id)block before:(id)beforeFilters after:(id)afterFilters report:(id)report is
    (self init)
    (set @context context)
    (set @description description)
    (set @block block)
    (set @hasPostponedBlock nil)
    (set @report report)
    ; create copies so that when the given arrays change later on, they don't change these
    (set @before (beforeFilters copy))
    (set @after (afterFilters copy))
    self
  )

  (- (id) runBeforeFilters is
    (@before each:(do (x) (@context instanceEval:x)))
  )

  (- (id) runAfterFiltersAndThrow:(id)shouldThrow is
    (try
      (@after each:(do (x) (@context instanceEval:x)))
      (catch (e)
        (if (shouldThrow) (throw e))
      )
    )
  )

  (- (id) run is
    (if (@report)
      ($BaconSummary addSpecification)
      (print "- #{@description}")
    )
    
    (set numberOfRequirementsBefore ($BaconSummary requirements))
    
    (try
      (try ; wrap before/requirement/after
        (self runBeforeFilters)
        (@context instanceEval:@block)
        (if (eq numberOfRequirementsBefore ($BaconSummary requirements))
          ; the requirement did not contain any assertions, so it flunked
          (throw ((BaconError alloc) initWithDescription:"flunked"))
        )
        (catch (e)
          ; don't allow after filters to throw, as it could result in an endless loop
          (self runAfterFiltersAndThrow:nil)
          (throw e)
        )
        ; ensure the after filters are always run, these however may throw, as we already ran the requirement
        (self runAfterFiltersAndThrow:t)
      )
      (catch (e) ; now really handle the bubbled exception
        (if (@report)
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
          ($BaconSummary addToErrorLog:e context:(@context name) specification:@description type:type)
        )
      )
    )
    
    (if (@report) (print "\n"))

    (unless (@hasPostponedBlock)
      ;(puts "will finish requirement!")
      (@context requirementDidFinish:self)
    )
  )

  (- (id) wait:(id)seconds thenRunBlock:(id)block is
    (set @postponedBlock block)
    (set @hasPostponedBlock t)
    ;(puts "SCHEDULING POSTPONED BLOCK!")
    (self performSelector:"runPostponedBlock" withObject:nil afterDelay:seconds)
    ; TODO is it correct that I need to call this here, again?!
    ((NSRunLoop mainRunLoop) runUntilDate:(NSDate dateWithTimeIntervalSinceNow:seconds))
  )

  (- (id) runPostponedBlock is
    ;(puts "GONNA RUN POSTPONED BLOCK!")
    ; TODO this needs to be run inside try-catch blocks and after filters should be run after this!
    (@context instanceEval:@postponedBlock)
    (@context requirementDidFinish:self)
  )
)
