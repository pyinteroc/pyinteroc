app [main] { pf: platform "./platform/main.roc" }

import pf.Task
import pf.Stdout
import pf.Stderr
import pf.Arg
import pf.Py

main = \str ->
    lst = Arg.list!
    when str is
        "STR1" -> run1 lst
        "STR2" -> run2 lst
        _ -> Stderr.line! "FUNCTION_DOESNT_EXIST"

run1 = \args ->
    fst = List.get args 0
    when fst is
        Ok s -> 
            Stdout.line! "OK: $(s)"
            Py.setresult! 1

        _ -> Stderr.line! "Error"

run2 = \args ->
    snd = List.get args 1
    when snd is
        Ok s -> 
            Stdout.line! "OK: $(s)"
            Py.setresult! 2

        _ -> Stderr.line! "Error"