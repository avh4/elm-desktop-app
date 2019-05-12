const { setWorldConstructor } = require("cucumber");
const fs = require("fs");

class CustomWorld {
  constructor() {
    this.Main = {
      main: {
        files: "\() -> Debug.todo \"\""
      }
    };
  }

  writeMain() {
    const stream = fs.createWriteStream("Main.elm");
    stream.write("import App\n");
    stream.write("import Html\n");
    stream.write("import Json.Encode as Json\n");
    stream.write("main = App.program\n");
    stream.write("    { init = ((), Cmd.none)\n");
    stream.write("    , update = \\() () -> ((), Cmd.none)\n");
    stream.write("    , subscriptions = \\() -> Sub.none\n");
    stream.write("    , view = \\() -> Html.text \"\"\n");
    stream.write(`    , files = ${this.Main.main.files}\n`);
    stream.write("    }\n");
    stream.close();
  }
}

setWorldConstructor(CustomWorld);
