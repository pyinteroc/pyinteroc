module [ 
    PyInt, PyNum, PyArgs
]

PyInt : [ I32, I64 ]
PyNum a : Num a

# PyArg : {
#     function: Str,
#     args: I32
# }

PyArgs : List Str
