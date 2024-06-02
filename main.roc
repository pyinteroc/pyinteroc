app [main] { pf: platform "./platform/main.roc" }

import pf.Task
import pf.Stdout
import pf.Stderr
import pf.Arg
import pf.Py

main = Arg.list! |> run

run = \args ->
    fst = List.get args 0
    when fst is
        Ok "STR1" -> 
            Stdout.line! "Calling the first funct..."
            when args is
                ["STR1",.. as rest] -> run1 rest
                _ -> Stderr.line "List Err"

        _ -> Stderr.line! "UNKNOWN FUNCTION"

run1 = \args ->
    fst = List.get args 0
    when fst is
        Ok s -> 
            Stdout.line! "OK: $(s)"
            Py.setresult! 1

        _ -> Stderr.line! "Error"

# run2 = \args ->
#     snd = List.get args 1
#     when snd is
#         Ok s -> 
#             Stdout.line! "OK: $(s)"
#             Py.setresult! 2

#         _ -> Stderr.line! "Error"

expect 1==1 ### need at least one test