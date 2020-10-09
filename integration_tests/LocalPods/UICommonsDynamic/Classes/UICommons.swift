
import Foundation

public struct UICommonsDynamic {
  private class DummyDynamic { }

  public static func jsonString(from fileName: String, fileExtension: String = ".json") -> String? {
    return dataFromFile(fileName, fileExtension: fileExtension)
      .flatMap { String(data: $0, encoding: .utf8) }
  }

  private static func dataFromFile(_ fileName: String, fileExtension: String) -> Data? {
    guard
      let bundlePath = Bundle(for: DummyDynamic.self).path(forResource: "UICommonsDynamic", ofType: "bundle"),
      let bundle = Bundle(path: bundlePath),
      let pathUrl = bundle.url(forResource: fileName, withExtension: fileExtension)
    else { return nil }
    return try? Data(contentsOf: pathUrl)
  }
}
