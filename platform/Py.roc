interface Py
    exposes [
        setresult,
    ]
    imports [Effect, InternalTask, Task.{ Task }]

### Stores the result to be returned to python
setresult : I32 -> Task {} *
setresult = 
    \n ->
        Effect.setResult n
                |> Effect.map Ok
                |> InternalTask.fromEffect
