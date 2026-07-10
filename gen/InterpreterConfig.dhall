-- Shared config shape threaded through the interpreter tree below
-- Interpreters/Project.dhall, which derives it from the Project model
-- (see `resolve` there) rather than from a separate resolve step.
let InterpreterConfig = { rootNamespace : List Text }

in  { Type = InterpreterConfig }
