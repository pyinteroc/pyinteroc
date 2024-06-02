app [main] { pf: platform "./platform/main.roc" }

import pf.Task
import pf.Stdout
import pf.Stderr
import pf.Arg
import pf.Py

main = Arg.list! |> run

### This is just a bunch of tests.
### Take them as examples of what is possible with PyInteROC

run = \args ->
    when args is
        ["STR1", .. as tail] -> run1 tail
        ["STR2", .. as tail] -> run2 tail
        ["sum_in_roc", .. as tail] -> runSumInROC tail

        _ -> Stderr.line! "UNKNOWN FUNCTION"

run1 = \args ->
    fst = List.get args 0
    when fst is
        Ok s -> 
            Stdout.line! "Selected the first function with arg: $(s)"
            Py.setresult! 1

        _ -> Stderr.line! "Error"

run2 = \args ->
    snd = List.get args 0
    when snd is
        Ok s -> 
            Stdout.line! "Selected the second function with arg: $(s)"
            Py.setresult! 2

        _ -> Stderr.line! "Error"

### Note this function actually performs effects
runSumInROC = \args -> Py.setresult (sumInROC args)

sumInROC = \args ->
    nums = List.map args numFromStr
    sumNums 0 nums

numFromStr = \s ->
    v = Str.toI32 s
    when v is
        Ok n -> n
        _  -> 0
        
sumNums : I32, List I32 -> I32
sumNums = \acc, nums ->
    when nums is
        [] -> acc
        [a, .. as tail] -> sumNums (acc + a) tail 

expect 1==1 ### need at least one test
expect sumInROC ["1", "10"] == 11
expect sumInROC ["1", "4", "7"] == 12