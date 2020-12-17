open Belt
open Command

open! Task
// from Editor Command to Tasks
let handle = command => {
  let header = View.Header.Plain(Command.toString(command))
  switch command {
  | Load => list{
      display(Plain("Loading ..."), Nothing),
      Task.WithStateP(
        state => {
          let document = VSCode.TextEditor.document(state.editor)
          let options = Some(VSCode.TextDocumentShowOptions.make(~preview=false, ()))
          // save the document before loading
          VSCode.TextDocument.save(document)
          // Issue #26 - don't load the document in preview mode
          ->Promise.flatMap(_ => VSCode.Window.showTextDocumentWithShowOptions(document, options))
          ->Promise.map(_ => list{})
        },
      ),
      AgdaRequest(Load),
    }
  | Quit => list{}
  | Restart => list{DispatchCommand(Load)}
  | Refresh => list{
      WithState(
        state => {
          Handle__Goal.updateRanges(state)
          Handle__Decoration.refresh(state)
        },
      ),
    }
  | Compile => list{AgdaRequest(Compile)}
  | ToggleDisplayOfImplicitArguments => list{AgdaRequest(ToggleDisplayOfImplicitArguments)}
  | ShowConstraints => list{AgdaRequest(ShowConstraints)}
  | SolveConstraints(normalization) =>
    Handle__Goal.caseSimple(
      goal => list{AgdaRequest(SolveConstraints(normalization, goal))},
      list{AgdaRequest(SolveConstraintsGlobal(normalization))},
    )
  | ShowGoals => list{AgdaRequest(ShowGoals)}
  | NextGoal => Handle__Goal.next
  | PreviousGoal => Handle__Goal.previous
  | SearchAbout(normalization) =>
    prompt(header, {body: None, placeholder: Some("name:"), value: None}, expr => list{
      AgdaRequest(SearchAbout(normalization, expr)),
    })
  | Give => Handle__Goal.case((goal, _) => list{AgdaRequest(Give(goal))}, goal => prompt(header, {
          body: None,
          placeholder: Some("expression to give:"),
          value: None,
        }, expr =>
          List.concat(Handle__Goal.modify(goal, _ => expr), list{AgdaRequest(Give(goal))})
        ), list{displayOutOfGoalError})
  | Refine =>
    Handle__Goal.caseSimple(goal => list{AgdaRequest(Refine(goal))}, list{displayOutOfGoalError})
  | ElaborateAndGive(normalization) =>
    let placeholder = Some("expression to elaborate and give:")
    Handle__Goal.case(
      (goal, expr) => list{AgdaRequest(ElaborateAndGive(normalization, expr, goal))},
      goal => prompt(header, {
          body: None,
          placeholder: placeholder,
          value: None,
        }, expr => list{AgdaRequest(ElaborateAndGive(normalization, expr, goal))}),
      list{displayOutOfGoalError},
    )
  | Auto =>
    Handle__Goal.caseSimple(goal => list{AgdaRequest(Auto(goal))}, list{displayOutOfGoalError})
  | Case =>
    let placeholder = Some("variable to case split:")
    Handle__Goal.case((goal, _) => list{AgdaRequest(Case(goal))}, goal => prompt(header, {
          body: Some("Please specify which variable you wish to split"),
          placeholder: placeholder,
          value: None,
        }, expr =>
          List.concat(
            // place the queried expression in the goal
            Handle__Goal.modify(goal, _ => expr),
            list{AgdaRequest(Case(goal))},
          )
        ), list{displayOutOfGoalError})
  | HelperFunctionType(normalization) =>
    let placeholder = Some("expression:")
    Handle__Goal.case(
      (goal, expr) => list{AgdaRequest(HelperFunctionType(normalization, expr, goal))},
      goal => prompt(header, {
          body: None,
          placeholder: placeholder,
          value: None,
        }, expr => list{AgdaRequest(HelperFunctionType(normalization, expr, goal))}),
      list{displayOutOfGoalError},
    )
  | InferType(normalization) =>
    let placeholder = Some("expression to infer:")
    Handle__Goal.case(
      (goal, expr) => list{AgdaRequest(InferType(normalization, expr, goal))},
      goal => prompt(header, {
          body: None,
          placeholder: placeholder,
          value: None,
        }, expr => list{AgdaRequest(InferType(normalization, expr, goal))}),
      prompt(header, {
        body: None,
        placeholder: placeholder,
        value: None,
      }, expr => list{AgdaRequest(InferTypeGlobal(normalization, expr))}),
    )
  | Context(normalization) =>
    Handle__Goal.caseSimple(
      goal => list{AgdaRequest(Context(normalization, goal))},
      list{displayOutOfGoalError},
    )
  | GoalType(normalization) =>
    Handle__Goal.caseSimple(
      goal => list{AgdaRequest(GoalType(normalization, goal))},
      list{displayOutOfGoalError},
    )
  | GoalTypeAndContext(normalization) =>
    Handle__Goal.caseSimple(
      goal => list{AgdaRequest(GoalTypeAndContext(normalization, goal))},
      list{displayOutOfGoalError},
    )
  | GoalTypeContextAndInferredType(normalization) =>
    Handle__Goal.case(
      (goal, expr) => list{AgdaRequest(GoalTypeContextAndInferredType(normalization, expr, goal))},
      // fallback to `GoalTypeAndContext` when there's no content
      goal => list{AgdaRequest(GoalTypeAndContext(normalization, goal))},
      list{displayOutOfGoalError},
    )
  | GoalTypeContextAndCheckedType(normalization) =>
    let placeholder = Some("expression to type:")
    Handle__Goal.case(
      (goal, expr) => list{AgdaRequest(GoalTypeContextAndCheckedType(normalization, expr, goal))},
      goal => prompt(header, {
          body: None,
          placeholder: placeholder,
          value: None,
        }, expr => list{AgdaRequest(GoalTypeContextAndCheckedType(normalization, expr, goal))}),
      list{displayOutOfGoalError},
    )
  | ModuleContents(normalization) =>
    let placeholder = Some("module name:")
    Handle__Goal.case(
      (goal, expr) => list{AgdaRequest(ModuleContents(normalization, expr, goal))},
      goal => prompt(header, {
          body: None,
          placeholder: placeholder,
          value: None,
        }, expr => list{AgdaRequest(ModuleContents(normalization, expr, goal))}),
      prompt(header, {
        body: None,
        placeholder: placeholder,
        value: None,
      }, expr => list{AgdaRequest(ModuleContentsGlobal(normalization, expr))}),
    )
  | ComputeNormalForm(computeMode) =>
    let placeholder = Some("expression to normalize:")
    Handle__Goal.case(
      (goal, expr) => list{AgdaRequest(ComputeNormalForm(computeMode, expr, goal))},
      goal => prompt(header, {
          body: None,
          placeholder: placeholder,
          value: None,
        }, expr => list{AgdaRequest(ComputeNormalForm(computeMode, expr, goal))}),
      prompt(header, {
        body: None,
        placeholder: placeholder,
        value: None,
      }, expr => list{AgdaRequest(ComputeNormalFormGlobal(computeMode, expr))}),
    )
  | WhyInScope =>
    let placeholder = Some("name:")
    Handle__Goal.case(
      (goal, expr) => list{AgdaRequest(WhyInScope(expr, goal))},
      goal => prompt(header, {
          body: None,
          placeholder: placeholder,
          value: None,
        }, expr => list{AgdaRequest(WhyInScope(expr, goal))}),
      prompt(header, {
        body: None,
        placeholder: placeholder,
        value: None,
      }, expr => list{AgdaRequest(WhyInScopeGlobal(expr))}),
    )
  | EventFromView(event) =>
    switch event {
    | Initialized => list{}
    | Destroyed => list{Destroy}
    | InputMethod(InsertChar(char)) => list{DispatchCommand(InputMethod(InsertChar(char)))}
    | InputMethod(ChooseSymbol(symbol)) => list{
        WithStateP(state => Handle__InputMethod.chooseSymbol(state, symbol)),
      }
    | PromptIMUpdate(MouseSelect(interval)) => list{
        WithStateP(state => Handle__InputMethod.select(state, [interval])),
      }
    | PromptIMUpdate(KeyUpdate(input)) => list{
        WithStateP(state => Handle__InputMethod.keyUpdatePromptIM(state, input)),
      }
    | PromptIMUpdate(BrowseUp) => list{DispatchCommand(InputMethod(BrowseUp))}
    | PromptIMUpdate(BrowseDown) => list{DispatchCommand(InputMethod(BrowseDown))}
    | PromptIMUpdate(BrowseLeft) => list{DispatchCommand(InputMethod(BrowseLeft))}
    | PromptIMUpdate(BrowseRight) => list{DispatchCommand(InputMethod(BrowseRight))}
    | PromptIMUpdate(Escape) => list{
        WithStateP(
          state => {
            if state.editorIM->IM.isActivated || state.promptIM->IM.isActivated {
              Handle__InputMethod.deactivate(state)
            } else {
              Promise.resolved(list{viewEvent(PromptInterrupt)})
            }
          },
        ),
      }
    | JumpToTarget(link) => list{
        WithState(
          state => {
            let document = VSCode.TextEditor.document(state.editor)
            Editor.focus(document)
            let path = document->VSCode.TextDocument.fileName->Parser.filepath
            switch link {
            | ToRange(NoRange) => ()
            | ToRange(Range(None, _intervals)) => ()
            | ToRange(Range(Some(filePath), intervals)) =>
              // only select the intervals when it's on the same file
              if path == filePath {
                let ranges = intervals->Array.map(View__Controller.fromInterval)
                Editor.Selection.setMany(state.editor, ranges)
              }
            | ToHole(index) =>
              let goal = Js.Array.find((goal: Goal.t) => goal.index == index, state.goals)
              switch goal {
              | None => ()
              | Some(goal) => Goal.setCursor(goal, state.editor)
              }
            }
          },
        ),
      }
    | MouseOver(_) => list{Debug("MouseOver")}
    | MouseOut(_) => list{Debug("MouseOut")}
    }
  | Escape => list{
      WithStateP(
        state => {
          if state.editorIM->IM.isActivated || state.promptIM->IM.isActivated {
            Handle__InputMethod.deactivate(state)
          } else {
            Promise.resolved(list{viewEvent(PromptInterrupt)})
          }
        },
      ),
    }
  | InputMethod(Activate) => list{WithStateP(state => Handle__InputMethod.activateEditorIM(state))}
  | InputMethod(InsertChar(char)) => list{
      WithStateP(state => Handle__InputMethod.insertChar(state, char)),
    }
  | InputMethod(BrowseUp) => list{WithStateP(Handle__InputMethod.moveUp)}
  | InputMethod(BrowseDown) => list{WithStateP(Handle__InputMethod.moveDown)}
  | InputMethod(BrowseLeft) => list{WithStateP(Handle__InputMethod.moveLeft)}
  | InputMethod(BrowseRight) => list{WithStateP(Handle__InputMethod.moveRight)}
  }
}
