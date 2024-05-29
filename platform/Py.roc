interface Py
    exposes [
        setresult,
    ]
    imports [Effect, InternalTask, Task.{ Task }, PyTypes.{ PyNum }]

### Stores the result to be returned to python
setresult : PyNum n -> Task {} *
setresult = 
    \pyn ->
        when pyn is
            Num n ->
                Effect.setResult n
                |> Effect.map Ok
                |> InternalTask.fromEffect
