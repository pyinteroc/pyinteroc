app [main] { pf: platform "./platform/main.roc" }


import pf.Stdout
import pf.Task

main = \py -> (run py)

run = \py ->
    f = py.function
    Stdout.line! "Number received!! $(f)"
    # Py.setresult (n+1)