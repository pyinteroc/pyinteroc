module [ 
    PyInt, PyNum, PyArg
]

PyInt : [ I32, I64 ]
PyNum a : Num a

PyArg : {
    function: Str,
    # args: I32
}
