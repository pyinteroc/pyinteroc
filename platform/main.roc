platform "python"
    requires {} { main : I32 -> Task {} [Exit I32 Str]_ }
    exposes []
    packages {}
    imports [Task.{Task}, Stderr.{line}]
    provides [mainForHost]

mainForHost : Str -> Task {} I32 as Fx
mainForHost =
    \_s -> Task.attempt (main 10) \res ->
        when res is
            Ok {} -> Task.ok {}

            Err (Exit code str) ->
                if Str.isEmpty str then
                    Task.err code
                else
                    line str
                    |> Task.onErr \_ -> Task.err code
                    |> Task.await \{} -> Task.err code

            Err err ->
                line "Program exited early with error: $(Inspect.toStr err)"
                |> Task.onErr \_ -> Task.err 1
                |> Task.await \_ -> Task.err 1
