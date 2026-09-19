import std.process.execute
import std.fs.Path

main(args: Array<String>): Int64 {
    match (args[0]) {
        case "pre-build" => onPreBuild()
        case "post-build" => onPostBuild()
        case _ => 0
    }
}

let SCRIPTS_DIR = Path("scripts")

@When[target == "aarch64-apple-ios-simulator"]
let TARGET_TRIPLE = "aarch64-apple-ios-simulator"
@When[target == "aarch64-apple-darwin"]
let TARGET_TRIPLE = "aarch64-apple-darwin"

func onPreBuild(): Int64 {
    execute("bash", [SCRIPTS_DIR.join("pre-build.sh").toString(), TARGET_TRIPLE])
}

func onPostBuild(): Int64 {
    execute("bash", [SCRIPTS_DIR.join("post-build.sh").toString(), TARGET_TRIPLE])
}
