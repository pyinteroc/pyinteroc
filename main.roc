app [main] { pf: platform "./platform/main.roc" }


import pf.Stdout
import pf.Task
import pf.Arg

main = \py -> (run py)

run = \ls ->
    # r = List.get s 1
    # when r is
    Stdout.line! "Number received!! $(ls)"
    lst = Arg.list!
    f = List.get lst 0
    when f is
        Ok _s -> Stdout.line! "OK"
        _ -> Stdout.line! "Error"

        # _ -> Stdout.line! "OUT_OF_BOUNDS"
    # Py.setresult (n+1)