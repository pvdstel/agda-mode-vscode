module Normalization = {
  type t =
    | Simplified
    | Instantiated
    | Normalised;

  let toString =
    fun
    | Simplified => "Simplified"
    | Instantiated => "Instantiated"
    | Normalised => "Normalised";
};

// module InputMethodAction = {
//   type t =
//     | Activate
//     | Deactivate
//     | Update(string, array(string));
// };

type t =
  | Load
  | Quit
  | NextGoal
  | PreviousGoal
  | Give
  | Refine
  | Auto
  | Case
  | InferType(Normalization.t)
  | GoalType(Normalization.t)
  | GoalTypeAndContext(Normalization.t)
  | ViewEvent(View.Event.t)
  | Escape
  | InputMethod(View.Request.InputMethod.t);

// for registering Keybindings
let names: array((t, string)) = [|
  (Load, "load"),
  (Quit, "quit"),
  (NextGoal, "next-goal"),
  (PreviousGoal, "previous-goal"),
  (Give, "give"),
  (Refine, "refine"),
  (Auto, "auto"),
  (Case, "case"),
  (InferType(Simplified), "infer-type[Simplified]"),
  (InferType(Instantiated), "infer-type[Instantiated]"),
  (InferType(Normalised), "infer-type[Normalised]"),
  (GoalType(Simplified), "goal-type[Simplified]"),
  (GoalType(Instantiated), "goal-type[Instantiated]"),
  (GoalType(Normalised), "goal-type[Normalised]"),
  (GoalTypeAndContext(Simplified), "goal-type-and-context[Simplified]"),
  (GoalTypeAndContext(Instantiated), "goal-type-and-context[Instantiated]"),
  (GoalTypeAndContext(Normalised), "goal-type-and-context[Normalised]"),
  (Escape, "escape"),
  (InputMethod(Activate), "input-symbol"),
|];

// for human
let toString =
  fun
  | Load => "Load"
  | Quit => "Quit"
  | NextGoal => "Next goal"
  | PreviousGoal => "Previous goal"
  | Give => "Give"
  | Refine => "Refine"
  | Auto => "Auto"
  | Case => "Case"
  | InferType(Simplified) => "Infer type (simplified)"
  | InferType(Instantiated) => "Infer type (instantiated)"
  | InferType(Normalised) => "Infer type (normalised)"
  | GoalType(Simplified) => "Goal type (simplified)"
  | GoalType(Instantiated) => "Goal type (instantiated)"
  | GoalType(Normalised) => "Goal type (normalised)"
  | GoalTypeAndContext(Simplified) => "Goal type and context (simplified)"
  | GoalTypeAndContext(Instantiated) => "Goal type and context (instantiated)"
  | GoalTypeAndContext(Normalised) => "Goal type and context (normalised)"
  | ViewEvent(_) => "View event"
  | Escape => "Escape"
  | InputMethod(Activate) => "Input symbol (activate)"
  | InputMethod(Deactivate) => "Input symbol (deactivate)"
  | InputMethod(Update(_)) => "Input symbol (update)";