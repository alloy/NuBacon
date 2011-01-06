(class BaconContext is NSObject
  ; use the dynamic `ivars' so the user can add ivars in before/after
  (ivars (id) name
         (id) before
         (id) after
         (id) requirements
         (id) printedName
         (id) delegate
         (id) currentRequirementIndex)
  
  (- (id) initWithName:(id)name requirements:(id)requirements is
    (self initWithName:name before:nil after:nil requirements:requirements)
  )

  (- (id) initWithName:(id)name before:(id)beforeFilters after:(id)afterFilters requirements:(id)requirements is
    (self init)

    ; register this context *before* evalling the requirements list, which may contain nested contexts
    ; that have to be after this one in the contexts list
    ((Bacon sharedInstance) addContext:self)

    (if (beforeFilters)
      (then (set @before (beforeFilters mutableCopy)))
      (else (set @before (NSMutableArray array)))
    )
    (if (afterFilters)
      (then (set @after (afterFilters mutableCopy)))
      (else (set @after (NSMutableArray array)))
    )

    (set @name name)
    (set @printedName nil)
    (set @currentRequirementIndex 0)

    (set @requirements (NSMutableArray array))
    (requirements each:(do (x) (eval x))) ; create a BaconRequirement for each entry in the quoted list

    self
  )

  (- (id) childContextWithName:(id)childName requirements:(id)requirements is
    ((BaconContext alloc) initWithName:"#{@name} #{childName}" before:@before after:@after requirements:requirements)
  )
  
  (- (id) name is @name)
  
  (- (id) setDelegate:(id)delegate is
    (set @delegate delegate)
  )
  
  (- (id) run is
    ; TODO
    (set report t)
    (if (report)
      (unless (@printedName)
        (set @printedName t)
        (puts "\n#{@name}")
      )
    )

    (set requirement (self currentRequirement))
    (requirement performSelector:"run" withObject:nil afterDelay:0)

    ; TODO is it correct that I need to call this here, again?!
    ((NSRunLoop mainRunLoop) runUntilDate:(NSDate dateWithTimeIntervalSinceNow:0.1))
  )

  (- (id) currentRequirement is
    (@requirements objectAtIndex:@currentRequirementIndex)
  )
  
  (- (id) requirementDidFinish:(id)requirement is
    (if (< (+ @currentRequirementIndex 1) (@requirements count))
      (then
        (set @currentRequirementIndex (+ @currentRequirementIndex 1))
        (self run)
      )
      (else
        ; DONE!
        (@delegate contextDidFinish:self)
      )
    )
  )

  (- (id) before:(id)block is
    (@before << block)
  )
  
  (- (id) after:(id)block is
    (@after << block)
  )
  
  (- (id) requirement:(id)description block:(id)block report:(id)report is
    (set requirement ((BaconRequirement alloc) initWithContext:self description:description block:block before:@before after:@after report:report))
    (@requirements << requirement)
  )
)
