const asyncBackend {.strdefine.} = "chronos"

when asyncBackend == "chronos":
  import
    chronos

  export
    chronos

  template fsAwait*(f: Future): untyped =
    await f

elif asyncBackend == "asyncdispatch":
  import
    std/asyncdispatch

  export
    asyncdispatch

  template fsAwait*(awaited: Future): untyped =
    let f = awaited
    yield f
    if not isNil(f.error):
      raise f.error
    f.read

  type Duration* = int
