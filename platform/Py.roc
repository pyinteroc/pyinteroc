interface Py
    exposes [
        setResult,
    ]
    imports [Effect, InternalTask, Task.{ Task }]

### Stores the result to be returned to python
setResult : I32 -> Task {} *
setResult = 
    \n ->
        Effect.setResult n
                |> Effect.map Ok
                |> InternalTask.fromEffect
