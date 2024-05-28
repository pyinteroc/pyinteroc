app [main] { pf: platform "./platform/main.roc" }


import pf.Stdout
import pf.Task
import pf.Py

main = \n -> (run n)

run = \n ->
    Stdout.line! "Number received!! $(Num.toStr n)"
    Py.setresult (n+1)