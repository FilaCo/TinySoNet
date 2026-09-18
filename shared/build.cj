import std.env.getVariable
import std.process.execute
import std.fs.{exists, Directory, Path, removeIfExists}

main(args: Array<String>) {
    let stage = args[0]
    match (stage) {
        case "pre-build" => onPreBuild()
        case "pre-clean" => onPreClean()
        case _ => ()
    }
}

func onPreBuild(): Unit {
    makeThirdParty()
}

func onPreClean(): Unit {
    cleanThirdParty()
}

let THIRD_PARTY_PATH = Path("third_party")
let THIRD_PARTY_OBJC_PATH = THIRD_PARTY_PATH.join("objc")

func makeThirdParty(): Unit {
    makeDirectoryIfNotExists(THIRD_PARTY_OBJC_PATH, recursive: true)
}

func cleanThirdParty(): Unit {
    removeIfExists(THIRD_PARTY_PATH, recursive: true)
}

func makeDirectoryIfNotExists(path: Path, recursive!: Bool = false) {
    if (exists(path)) {
        return
    }

    Directory.create(path, recursive: recursive)
}
