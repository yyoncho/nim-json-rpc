import
  std/json,
  unittest,
  streams,
  faststreams/async_backend,
  faststreams/asynctools_adapters,
  ../json_rpc/streamconnection

type
  DemoObject* = object
    foo*: int
    bar*: int

# for testing purposes
var
  cachedInput: JsonNode
  cachedDemoObject = newFuture[DemoObject]();

proc echo(params: JsonNode): Future[RpcResult] {.async,
    raises: [CatchableError, Exception].} =
  {.gcsafe.}:
    cachedInput = params;
  return some(StringOfJson($params))

proc notifyDemoObject(params: DemoObject): Future[void] {.async} =
  {.gcsafe.}:
    cachedDemoObject.complete(params);
  return

suite "Client/server over JSONRPC":
  let pipeServer = createPipe();
  let pipeClient = createPipe();

  proc echoDemoObject(params: DemoObject): Future[DemoObject] {.async,
      raises: [CatchableError, Exception].} =
    return params

  proc echoDemoObjectRaiseError(params: DemoObject): Future[DemoObject] {.async,
      raises: [CatchableError, Exception].} =
    raise newException(ValueError, "ValueError")

  let serverConnection = StreamConnection.new(pipeServer);
  serverConnection.register("echo", echo)
  serverConnection.register("echoDemoObject", echoDemoObject)
  serverConnection.register("echoDemoObjectRaise", echoDemoObjectRaiseError)
  serverConnection.registerNotification("demoObjectNotification", notifyDemoObject)

  discard serverConnection.start(asyncPipeInput(pipeClient));

  let clientConnection = StreamConnection.new(pipeClient);
  discard clientConnection.start(asyncPipeInput(pipeServer));

  test "Simple call.":
    let response = clientConnection.call("echo", %"input").waitFor().getStr
    doAssert (response == "input")
    doAssert (cachedInput.getStr == "input")

  test "Call with object.":
    let input =  DemoObject(foo: 1);
    let response = clientConnection.call("echoDemoObject", %input).waitFor()
    assert(to(response, DemoObject) == input)

  test "Sending notification.":
    let input =  DemoObject(foo: 2);
    clientConnection.notify("demoObjectNotification", %input).waitFor()
    assert(cachedDemoObject.waitFor == input)

  test "Call with object/exception":
    let input =  DemoObject(foo: 1);
    try:
      discard clientConnection.call("echoDemoObjectRaise", %input).waitFor()
      doAssert false
    except ValueError as e:
      discard # expected


  pipeClient.close()
  pipeServer.close()

suite "Parsing from stream":
  test "Read from file":
    let msg = waitFor readMessage(newFileStream("tests/jsonmessage"))
    doAssert some("[1,2,3]\n") == msg
